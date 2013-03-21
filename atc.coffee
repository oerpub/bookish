define [
  'underscore'
  'backbone'
  'bookish/controller'
  'bookish/models'
  'bookish/media-types'
  'bookish/auth'
  'css!bookish'
], (_, Backbone, Controller, Models, MEDIA_TYPES, Auth) ->

  DEBUG = true

  # Generate UUIDv4 id's (from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript)
  uuid = b = (a) ->
    (if a then (a ^ Math.random() * 16 >> a / 4).toString(16) else ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, b))



  writeFile = (path, text, commitText) ->
    Auth.getRepo().write Auth.get('branch'), "#{Auth.get('rootPath')}#{path}", text, commitText

  readFile = (path) -> Auth.getRepo().read Auth.get('branch'), "#{Auth.get('rootPath')}#{path}"
  readDir =  (path) -> Auth.getRepo().contents Auth.get('branch'), path

  ROOT_URL = ''
  WORKSPACE_URL = "#{ROOT_URL}/workspace/"

  Models.BaseContent::url = -> "#{ROOT_URL}/module/#{@id}"
  Models.BaseBook::url = -> "#{ROOT_URL}/collection/#{@id}"

  # HACK: so the user is always logged in
  Auth.set
    username: 'test'
    password: 'test'

  # HACK: to always get an authenticated user
  # Originally from `Backbone.sync`.
  # Added the request header
  Backbone.ajax = (config) ->
    config = _.extend config, {headers: {'REMOTE_USERURI': 'cnxuser:75e06194-baee-4395-8e1a-566b656f6920'}}
    Backbone.$.ajax.apply(Backbone.$, [config])

  AtcWorkspace = Models.DeferrableCollection.extend
    url: WORKSPACE_URL
    # Workspace comes in with the following format:
    #     [
    #       {mediaType: 'application/vnd.org.cnx.folder', id: 'cnxfolder:123', title: 'Some Title', ...} ...],
    #       {mediaType: 'application/vnd.org.cnx.module', id: 'cnxmodule:123', title: 'Some Title', ...} ...],
    #       {mediaType: 'application/vnd.org.cnx.collection', id: 'cnxcollection:123', title: 'Some Title', ...} ...],
    #     ]
    #
    # Convert that to something sane.
    parse: (results) ->
      # Rewrite the `mediaType` so it matches what the bookish editor expects.
      results = for item in results
        ContentType = MEDIA_TYPES.get(item.mediaType).constructor
        model = new ContentType(item)
        model

      results


  Models.WORKSPACE = new AtcWorkspace()

  resetDesktop = ->
    # Clear out all the content and reset `EPUB_CONTAINER` so it is always fetched
    Models.ALL_CONTENT.reset()
    Models.WORKSPACE.fetch()

    # Begin listening to route changes
    # and load the initial views based on the URL.
    if not Backbone.History.started
      Controller.start()
    Backbone.history.navigate('workspace')


  # Clear everything and refetch when the
  STORED_KEYS = ['username', 'password']
  Auth.on 'change', () =>
    if not _.isEmpty(_.pick Auth.changed, STORED_KEYS)
      # If the user changed login state then don't reset the desktop
      return if Auth.get('password') and not Auth.previousAttributes()['password']

      resetDesktop()


  # Load up the workspace and show the signin modal dialog
  if not Backbone.History.started
    Controller.start()
  Backbone.history.navigate('workspace')

