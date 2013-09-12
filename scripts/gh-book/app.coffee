define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!helpers/logger'
  'cs!session'
  'cs!collections/content'
  'cs!collections/media-types'
  'cs!gh-book/epub-container'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/opf-file'
  'cs!gh-book/toc-node'
  'cs!gh-book/binary-file'
  'cs!gh-book/auth'
  'cs!gh-book/remote-updater'
  'cs!gh-book/loading'
  'cs!configs/github.coffee'
  'less!styles/main'
  'less!gh-book/gh-book'
], ($, _, Backbone, Marionette, logger, session, allContent, mediaTypes, EpubContainer, XhtmlFile, OpfFile, TocNode, BinaryFile, WelcomeSignInView, remoteUpdater, LoadingView, config) ->

  # Stop logging.
  logger.stop()

  # Returns a promise that is resolved once all promises in the array `promises`
  # are resolved.
  onceAll = (promises) -> return $.when.apply($, promises)

  # Singleton that gets reloaded when the repo changes
  epubContainer = new EpubContainer()

  allContent.on 'add', (model, collection, options) ->
    return if options.loading

    # If the new model is a book then add it to epubContainer
    # Otherwise, add it to the manifest for all the books (Better safe than sorry)
    switch model.mediaType
      when OpfFile::mediaType
        epubContainer.addChild(model)
      else
        allContent.each (book) ->
          book.manifest?.add(model) # Only books have a manifest


  # The WelcomeSignInView is overloaded to show Various Dialogs.
  #
  # - SignIn
  # - Repo Settings
  #
  # When there is a failure show the Settings/SignIn Modal
  welcomeView = new WelcomeSignInView {model:session}



  # This is a utility that wraps a promise and alerts when the promise fails.
  onFail = (promise, message='There was a problem.') ->
    complete = 0
    total = 0

    promise.progress (msg) =>
      switch msg.type
        when 'start'  then total++
        when 'end'    then complete++
      console.log "Progress: #{complete}/#{total}: ", msg

    return promise.fail (err) =>
      repoUser = session.get('repoUser')
      repoName = session.get('repoName')
      branch = session.get('branch') or ''
      branch = "##{branch}" if branch

      # Show the WelcomeView's settings modal if there was a connection problem
      try
        App.main.show(welcomeView)
        welcomeView.editSettingsModal(message)
      catch err
        alert("#{message} Are you pointing to a valid book? Using github/#{repoUser}/#{repoName}#{branch}")


  App = new Marionette.Application()

  App.addRegions
    main: '#main'


  App.addInitializer (options) ->

    # Register media types for editing
    mediaTypes.add EpubContainer
    mediaTypes.add XhtmlFile
    mediaTypes.add OpfFile
    mediaTypes.add TocNode
    mediaTypes.add BinaryFile, {mediaType:'image/png'}
    mediaTypes.add BinaryFile, {mediaType:'image/jpeg'}


    # Views use anchors with hrefs so catch the click and send it to Backbone
    $(document).on 'click', 'a:not([data-bypass]):not([href="#"])', (e) ->
      external = new RegExp('^((f|ht)tps?:)?//')
      href = $(@).attr('href')
      defaultPrevented = e.isDefaultPrevented()

      e.preventDefault()

      if external.test(href)
        if not defaultPrevented
          window.open(href, '_blank')
      else
        if href then Backbone.history.navigate(href, {trigger: true})


    # Populate the Session Model from localStorage
    STORED_KEYS = ['repoUser', 'repoName', 'branch', 'id', 'password', 'token']
    props = {}
    _.each STORED_KEYS, (key) ->
      value = window.sessionStorage.getItem key
      props[key] = value if value
    session.set props

    # On change, store info to localStorage
    session.on 'change', () =>
      # Update session storage
      for key in STORED_KEYS
        value =  session.get key
        if value
          window.sessionStorage.setItem key, value
        else
          window.sessionStorage.removeItem key, value



    # Github read/write and repo configuration

    writeFile = (path, model, commitText, isBase64) ->
      text = model.serialize()
      lastSeenSha = remoteUpdater.lastSeenSha
      promise = $.Deferred()
      # .write expects the text to be base64 encoded so no need to convert it
      session.getBranch().write(path, text, commitText, isBase64, lastSeenSha)
      .done((val) => model.onSaved?(); promise.resolve(val))
      .fail (err) =>
        # Get the new lastSeenSha
        remoteUpdater.pollUpdates().then () =>
            # Probably a conflict because of a remote change.
            # Resolve the changes and save again
            model.reload()
            .fail((err) => promise.reject(err))
            .done () =>
              # Probably a patch/cache problem.
              # Clear the cache and try again
              session.getClient().clearCache?()
              writeFile(path, model, commitText, isBase64)
              .fail((err) => promise.reject(err))
              .done (val) => promise.resolve(val)


      return promise

    writeFiles = (models, commitText) ->
      parentCommitSha = remoteUpdater.lastSeenSha
      promise = $.Deferred()

      # For each model, build a map of changed Content
      changedFiles = {}
      _.each models, (model) ->
        changedFiles[model.id] =
          isBase64: model.isBinary
          content: model.serialize()

      promise.done -> _.map models, (model) -> console.log 'saved', model.id
      promise.fail -> _.map models, (model) -> console.log 'failed saving', model.id

      session.getBranch().writeMany(changedFiles, commitText, parentCommitSha)
      .done((val) =>
        # Fire the onSave event on all the changed models
        _.map models, (model) -> model.onSaved?()
        promise.resolve(val)
      )
      .fail (err) =>
        # Probably a conflict because of a remote change.
        # Resolve the changes and save again
        #
        # Reload all the models (merging local changes along the way)
        # and, at the same time get the new lastSeenSha
        remoteUpdater.pollUpdates().then () =>
          # Probably a patch/cache problem.
          # Clear the cache and try again
          session.getClient().clearCache?()
          writeFiles(models, commitText)
          .fail((err) => promise.reject(err))
          .done (val) => promise.resolve(val)

      return promise


    readFile = (path, isBinary) -> session.getBranch().read path, isBinary
    readDir =        (path) -> session.getBranch().contents   path


    Backbone.sync = (method, model, options) ->

      path = model.id or model.url?() or model.url

      console.log method, path
      ret = null
      switch method
        when 'read' then ret = readFile(path, model.isBinary)
        when 'update' then ret = writeFile(path, model, 'Editor Update', model.isBinary)
        when 'create' then ret = writeFile(path, model, 'Editor Create', model.isBinary)
        else throw "Model sync method not supported: #{method}"

      ret.done (value) => options?.success?(value)
      ret.fail (error) => options?.error?(ret, error)
      return ret

    allContent_save = (options) ->
      # Save all the models that have changes
      changedModels = @filter (model) -> model.isDirty()

      writeFiles(changedModels)


    allContent.save = allContent_save.bind(allContent)

  App.on 'start', () ->

    # Update the width/height of main so we can have CSS that uses `bottom: 0` or `right: 0`
    $window = $(window)
    onWindowResize = () =>
      App.main.$el.css
        width: $window.width()
        height: $window.height()

    $window.resize onWindowResize

    startRouting = () ->
      # Remove cyclic dependency. Controller depends on `App.main` region
      require ['cs!controllers/routing'], (controller) =>

        # Tell the controller which region to put all the views/layouts in
        controller.main = App.main

        # Custom routes to configure the Github User and Repo from the browser
        router = new class GithubRouter extends Backbone.Router

          setDefaultRepo = () ->
            if not session.get('repoName')
              options = {}
              options.silent = true if not 'id' and not 'token'
              session.set config.defaultRepo, options


          routes:
            'repo/:repoUser/:repoName':         'configRepo'
            'repo/:repoUser/:repoName/:branch': 'configRepo'

            '':             'goDefault'
            'workspace':    'goWorkspace'
            'edit/:id':     'goEdit' # Edit an existing piece of content (id can be a URL-encoded path)

          _loadFirst: () ->
            setDefaultRepo()
            promise = onFail(remoteUpdater.start(), 'There was a problem starting the remote updater')
            .then () =>
              return onFail(epubContainer.load(), 'There was a problem loading the repo')

            App.main.show(new LoadingView {model:epubContainer, promise:promise})
            return promise

          configRepo: (repoUser, repoName, branch='') ->
            session.set
              repoUser: repoUser
              repoName: repoName
              branch:   branch

            # The app listens to session onChange events and will call .goDefault
            # It listens to 'change' because the auth view may also change the session


          # Delay the route handling until the initial content is loaded
          # TODO: Move this into the controller
          goWorkspace: () ->
            @_loadFirst().done () => controller.goWorkspace()
          goEdit: (id, contextModel=null)    ->
            @_loadFirst().done () => controller.goEdit(id, contextModel)
          goDefault: () ->
            _controller = @ # Explicit is better than confusing
            @_loadFirst().done () ->
              require ['cs!gh-book/opf-file'], (OpfFile) ->
                # Find the first opf file.
                opf = allContent.findWhere({mediaType: OpfFile.prototype.mediaType})
                if opf
                  # The first item in the toc is always the opf file, followed by the
                  # TOC nodes.
                  controller.goEdit opf.tocNodes.at(1), opf
                else
                  _controller.goWorkspace()


        session.on 'change', () =>
          if not _.isEmpty _.pick(session.changed, ['repoUser', 'repoName', 'branch'])
            remoteUpdater.stop()
            onFail(epubContainer.reload(), 'There was a problem re-loading the repo')
            router.goDefault()


        Backbone.history.start
          pushState: false
          hashChange: true
          root: ''



    # If localStorage does not contain a password or OAuth token then show the SignIn modal.
    # Otherwise, load the workspace
    if session.get('password') or session.get('token')
      # Use the default book if one is not already set
      if not session.get 'repoName'
        session.set config.defaultRepo
      startRouting()
    else
      # The user has not logged in yet so pop up the modal
      welcomeView.once 'close', () =>
        # Use the default book if one is not already set
        if not session.get 'repoName'
          session.set config.defaultRepo
        startRouting()
      App.main.show(welcomeView)
      welcomeView.signInModal()

  return App
