define [
  'underscore'
  'backbone'
  'bookish/controller'
  'bookish/models'
  'epub/models'
  'bookish/auth'
  'gh-book/views'
  'css!bookish'
], (_, Backbone, Controller, AtcModels, EpubModels, Auth, Views) ->

  DEBUG = true

  # Generate UUIDv4 id's (from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript)
  uuid = b = (a) ->
    (if a then (a ^ Math.random() * 16 >> a / 4).toString(16) else ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, b))



  writeFile = (path, text, commitText) ->
    Auth.getRepo().write Auth.get('branch'), "#{Auth.get('rootPath')}#{path}", text, commitText

  readFile = (path) -> Auth.getRepo().read Auth.get('branch'), "#{Auth.get('rootPath')}#{path}"
  readDir =  (path) -> Auth.getRepo().contents Auth.get('branch'), path




  Backbone.sync = (method, model, options) ->
    success = options?.success
    error = options?.error

    callback = (err, value) ->
      return error?(model, err, options) if err
      return success?(model, value, options)

    path = model.id or model.url?() or model.url

    console.log method, path if DEBUG
    ret = null
    switch method
      when 'read' then ret = readFile(path, callback)
      when 'update' then ret = writeFile(path, model.serialize(), 'Editor Save', callback)
      when 'create'
        # Create an id if this model has not been saved yet
        id = _uuid()
        model.set 'id', id
        ret = writeFile(path, model.serialize(), callback)
      else throw "Model sync method not supported: #{method}"

    ret.done (value) => success?(model, value, options)
    ret.fail (error) => error?(model, error, options)
    return ret





  AtcModels.SearchResults = AtcModels.SearchResults.extend
    initialize: ->
      @add AtcModels.ALL_CONTENT.models

      AtcModels.ALL_CONTENT.on 'reset',  () => @reset()
      AtcModels.ALL_CONTENT.on 'add',    (model) => @add model
      AtcModels.ALL_CONTENT.on 'remove', (model) => @remove model



  resetDesktop = ->
    # Clear out all the content and reset `EPUB_CONTAINER` so it is always fetched
    AtcModels.ALL_CONTENT.reset()
    EpubModels.EPUB_CONTAINER.reset()
    EpubModels.EPUB_CONTAINER._promise = null

    # Begin listening to route changes
    # and load the initial views based on the URL.
    if not Backbone.History.started
      Controller.start()
    Backbone.history.navigate('workspace')


    # Change how the workspace is loaded (from `META-INF/content.xml`)
    #
    # `EPUB_CONTAINER` will fill in the workspace just by requesting files
    EpubModels.EPUB_CONTAINER.loaded().then () ->

      # fetch all the book contents so the workspace is populated
      EpubModels.EPUB_CONTAINER.each (book) -> book.loaded()




  # Clear everything and refetch when the
  STORED_KEYS = ['repoUser', 'repoName', 'branch', 'rootPath', 'username', 'password']
  Auth.on 'change', () =>
    if not _.isEmpty(_.pick Auth.changed, STORED_KEYS)
      # If the user changed login state then don't reset the desktop
      return if Auth.get('rateRemaining') and Auth.get('password') and not Auth.previousAttributes()['password']

      resetDesktop()
      # Update session storage
      for key, value of Auth.toJSON()
        @sessionStorage?.setItem key, value

  #Auth.on 'change:repoName', resetDesktop
  #Auth.on 'change:branch', resetDesktop
  #Auth.on 'change:rootPath', resetDesktop


  # Load up the workspace and show the signin modal dialog
  if not Backbone.History.started
    Controller.start()
  Backbone.history.navigate('workspace')


  # Load from sessionStorage
  props = {}
  _.each STORED_KEYS, (key) ->
    value = @sessionStorage?.getItem key
    props[key] = value if value
  Auth.set props

  $signin = jQuery('#sign-in-modal')
  $signin.modal('show')
  $signin.on 'hide', ->
    # Delay so we have a chance to save the login/password if the user clicked "Sign In"
    setTimeout resetDesktop, 100
