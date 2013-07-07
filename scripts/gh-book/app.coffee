define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'github'
  'cs!helpers/logger'
  'cs!session'
  'cs!collections/content'
  'cs!collections/media-types'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/opf-file'
  'cs!gh-book/binary-file'
  'cs!gh-book/welcome-sign-in'
  'less!styles/main'
  'less!gh-book/gh-book'
], ($, _, Backbone, Marionette, Github, logger, session, allContent, mediaTypes, XhtmlFile, OpfFile, BinaryFile, WelcomeSignInView) ->

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
    mediaTypes.add BinaryFile, {mediaType:'image/jpg'}
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
    STORED_KEYS = ['repoUser', 'repoName', 'branch', 'rootPath', 'id', 'password']
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
        window.sessionStorage.setItem key, value



    # Github read/write and repo configuration

    getRepo = () ->
      config =
        auth: (if session.get('token') then 'oauth' else 'basic')
        token:    session.get('token')
        id:       session.get('id')
        password: session.get('password')

      gh = new Github(config)
      gh.getRepo(session.get('repoUser'), session.get('repoName'))


    writeFile = (path, text, commitText) ->
      getRepo().write session.get('branch'), "#{session.get('rootPath')}#{path}", text, commitText

    readFile =       (path) -> getRepo().read       session.get('branch'), "#{session.get('rootPath')}#{path}"
    readBinaryFile = (path) -> getRepo().readBinary session.get('branch'), "#{session.get('rootPath')}#{path}"
    readDir =        (path) -> getRepo().contents   session.get('branch'), path


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


    startRouting = () ->
      # Remove cyclic dependency. Controller depends on `App.main` region
      require ['cs!controllers/routing'], (controller) ->

        # Custom routes to configure the Github User and Repo from the browser
        new class GithubRouter extends Backbone.Router
          routes:
            'repo/:repoUser/:repoName':         'configRepo'
            'repo/:repoUser/:repoName/:branch': 'configRepo'

            '':             'workspace' # Show the workspace list of content
            'workspace':    'workspace'
            'edit/*id':     'edit' # Edit an existing piece of content (id can be a path)

          configRepo: (repoUser, repoName, branch='master') ->
            session.set
              'repoUser': repoUser
              'repoName': repoName
              'branch': branch

            @workspace()

          # Delay the route handling until the initial content is loaded
          # TODO: Move this into the controller
          workspace: () -> allContent.load().done () => controller.workspace()
          edit: (id)    -> allContent.load().done () => controller.edit(id)


        Backbone.history.start
          pushState: false
          hashChange: true
          root: ''


    signIn = new WelcomeSignInView {model:session}
    signIn.once 'close', startRouting
    App.main.show(signIn)
    signIn.signInModal()

  return App
