define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!helpers/logger'
  'cs!session'
  'cs!collections/content'
  'cs!collections/media-types'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/opf-file'
  'cs!gh-book/binary-file'
  'cs!gh-book/welcome-sign-in'
  'cs!gh-book/remote-updater'
  'less!styles/main'
  'less!gh-book/gh-book'
], ($, _, Backbone, Marionette, logger, session, allContent, mediaTypes, XhtmlFile, OpfFile, BinaryFile, WelcomeSignInView, remoteUpdater) ->

  # Stop logging.
  logger.stop()

  App = new Marionette.Application()

  App.addRegions
    main: '#main'


  App.addInitializer (options) ->

    # Register media types for editing
    mediaTypes.add XhtmlFile
    mediaTypes.add OpfFile
    mediaTypes.add BinaryFile, {mediaType:'image/png'}
    mediaTypes.add BinaryFile, {mediaType:'image/jpeg'}


    # Views use anchors with hrefs so catch the click and send it to Backbone
    $(document).on 'click', 'a:not([data-bypass])', (e) ->
      external = new RegExp('^((f|ht)tps?:)?//')
      href = $(@).attr('href')

      e.preventDefault()

      if external.test(href)
        window.open(href, '_blank')
      else
        if href then Backbone.history.navigate(href, {trigger: true})


    # Populate the Session Model from localStorage
    STORED_KEYS = ['repoUser', 'repoName', 'id', 'password', 'token']
    props = {}
    _.each STORED_KEYS, (key) ->
      value = window.sessionStorage.getItem key
      props[key] = value if value
    session.set props, {silent:true}

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

    writeFile = (path, text, commitText) ->
      session.getBranch().write path, text, commitText

    readFile =       (path) -> session.getBranch().read       path
    readBinaryFile = (path) -> session.getBranch().read       path, true # isBinary == true
    readDir =        (path) -> session.getBranch().contents   path


    Backbone.sync = (method, model, options) ->

      path = model.id or model.url?() or model.url

      console.log method, path
      ret = null
      switch method
        when 'read'
          if model.isBinary
            ret = readBinaryFile(path)
          else
            ret = readFile(path)
        when 'update' then ret = writeFile(path, model.serialize(), 'Editor Save')
        when 'create'
          # Create an id if this model has not been saved yet
          id = _uuid()
          model.set 'id', id
          ret = writeFile(path, model.serialize())
        else throw "Model sync method not supported: #{method}"

      ret.done (value) => options?.success?(value)
      ret.fail (error) => options?.error?(ret, error)
      return ret


  App.on 'start', () ->

    startRouting = () ->
      # Remove cyclic dependency. Controller depends on `App.main` region
      require ['cs!controllers/routing'], (controller) =>

        # Tell the controller which region to put all the views/layouts in
        controller.main = App.main

        # Custom routes to configure the Github User and Repo from the browser
        new class GithubRouter extends Backbone.Router

          setDefaultRepo = () ->
            if not session.get('repoName')
              DEFAULT_CONFIG =
                'repoUser': 'Connexions'
                'repoName': 'atc'
                'branch'  : 'sample-book'
              options = {}
              options.silent = true if not 'id' and not 'token'
              session.set DEFAULT_CONFIG, options


          routes:
            'repo/:repoUser/:repoName':         'configRepo'
            'repo/:repoUser/:repoName/:branch': 'configRepo'

            '':             'goWorkspace' # Show the workspace list of content
            'workspace':    'goWorkspace'
            'edit/*id':     'goEdit' # Edit an existing piece of content (id can be a path)

          configRepo: (repoUser, repoName, branch='') ->
            session.set
              repoUser: repoUser
              repoName: repoName
              branch:   branch

            remoteUpdater.stop()
            allContent.reload()
            @goWorkspace()

          # Delay the route handling until the initial content is loaded
          # TODO: Move this into the controller
          goWorkspace: () ->
            setDefaultRepo()
            remoteUpdater.start()
            .fail((err) => alert('There was a problem starting the remote updater. Are you pointing to a valid book?'))
            .done () =>
              allContent.load()
              .fail((err) => alert('There was a problem loading the repo. Are you pointing to a valid book?'))
              .done () => controller.goWorkspace()
          goEdit: (id)    ->
            setDefaultRepo()
            remoteUpdater.start()
            .fail((err) => alert('There was a problem starting the remote updater. Are you pointing to a valid book?'))
            .done () =>
              allContent.load()
              .fail((err) => alert('There was a problem loading the repo. Are you pointing to a valid book?'))
              .done () => controller.goEdit(id)


        Backbone.history.start
          pushState: false
          hashChange: true
          root: ''


    signIn = new WelcomeSignInView {model:session}
    signIn.once 'close', () =>
      if not session.get 'repoName'
        session.set
          'repoUser': 'Connexions'
          'repoName': 'atc'
          'branch'  : 'sample-book'
          'token'   : null         # Set your token here if you want

      startRouting()
    App.main.show(signIn)
    signIn.signInModal()

  return App
