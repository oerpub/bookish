define [
  'underscore'
  'backbone'
  'bookish/controller'
  'bookish/models'
  'bookish/media-types'
  'bookish/auth'
  'hbs!atc-nav-serialize'
  'css!bookish'
], (_, Backbone, Controller, Models, MEDIA_TYPES, Auth, NAV_SERIALIZE) ->

  DEBUG = true


  ROOT_URL = ''
  WORKSPACE_URL = "#{ROOT_URL}/workspace/"

  # Find out who the current user is logged in as
  Auth.url = -> "#{ROOT_URL}/me/"
  Auth.fetch()

  Models.BaseContent::url = ->
    return "#{ROOT_URL}/module/" if @isNew()
    "#{ROOT_URL}/module/#{@id}"
  Models.BaseBook::url = -> "#{ROOT_URL}/collection/#{@id}"


  # When the `navTreeStr` changes, update the body with HTML
  oldBaseBook_initialize = Models.BaseBook::initialize
  Models.BaseBook::initialize = ->
    oldBaseBook_initialize.apply(@, arguments)
    # When the `navTreeStr` is changed on the package,
    # Change it in the book body
    @on 'change:navTreeStr', (model, navTreeStr) =>
      @set {body: NAV_SERIALIZE JSON.parse navTreeStr}


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

    # If new content is created/loaded, add it to the workspace
    initialize: ->
      @on 'add', (model) => Models.ALL_CONTENT.add model
      @on 'reset', (collection) => Models.ALL_CONTENT.add @models

      @listenTo Models.ALL_CONTENT, 'add', (model) =>
        @add model


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

