# Authoring Tools
# =======
# This file attaches all the sync hooks necessary to make the `bookish` editor
# read/write to the Connexions repository.
#
define [
  'module' # Obtain the requirejs module config
  'underscore'
  'backbone'
  'jquery'
  'bookish/controller'
  'bookish/models'
  'bookish/views'
  'bookish/media-types'
  'bookish/auth'
  'hbs!atc-nav-serialize'
], (module, _, Backbone, jQuery, Controller, Models, Views, MEDIA_TYPES, Auth, NAV_SERIALIZE) ->

  # Load debug options from the module config
  DEBUG_USER = module.config().debugUser
  ROOT_URL = module.config().rootUrl or ''


  # HACK: to always get an authenticated user
  # by adding a request header
  if DEBUG_USER
    Backbone.ajax = (config) ->
      config = _.extend config,
        headers:
          'X-REMOTEAUTHID': DEBUG_USER
      Backbone.$.ajax.apply(Backbone.$, [config])


  WORKSPACE_URL = "#{ROOT_URL}/workspace/"

  # Find out who the current user is logged in as
  Auth.url = -> "#{ROOT_URL}/me/"
  Auth.fetch()


  Models.BaseContent::urlPrefix = "#{ROOT_URL}/module"
  Models.BaseBook::urlPrefix    = "#{ROOT_URL}/collection"
  Models.Folder::urlPrefix      = "#{ROOT_URL}/folder"

  # All the content types extend `Models.Deferrable`
  # so override the URL here.
  # Since the webserver redirects when a URL does not end in a `/`, override
  # the default URL-generation logic in `Backbone` to append a `/` when POSTing
  # a new piece of content.
  Models.Deferrable::url = ->
    return "#{@urlPrefix}/" if @isNew()
    "#{@urlPrefix}/#{@id}"

  # When the `navTreeRoot` changes, update the body with HTML
  Models_BaseBook_initialize = Models.BaseBook::initialize
  Models.BaseBook::initialize = ->
    Models_BaseBook_initialize.apply(@, arguments)

    # When the body of the collection changes, update the `navTreeRoot`
    @on 'change:body', (model, body, options) =>
      return if options?.doNotReparse
      # Older implementations of the server returned the `body`
      # as an array of characters instead of a string.
      # If that happens, concat them into a string.
      if body instanceof Array
        return model.set 'body', body.join('')
      $body = jQuery(body)
      # Pull out the `<nav>` element (which contains a `<ol>`)
      # representing the structure of a book.
      if $body.is 'nav'
        $root = $body
      else
        $root = $body.find('nav').first()
      if $root[0]
        navTree = @parseNavTree($root)
        @navTreeRoot.reset navTree.children

    # When the `navTreeRoot` is changed on the package,
    # Change it in the book body
    @navTreeRoot.on 'all', => @set {body: NAV_SERIALIZE @navTreeRoot.toJSON()}, {doNotReparse:true}
    @navTreeRoot.descendants.on 'all', => @set {body: NAV_SERIALIZE @navTreeRoot.toJSON()}, {doNotReparse:true}


  # A folder contains a title and a collection of items in the folder
  Models.Folder::parse = (obj) ->
    models = []
    _.each obj.body, (item) ->
      # **FIXME:** This is a HACK. Folder.body should contain an array
      # of `{id: , mediaType: , title: }` at the very least
      if 'string' == typeof item
        hackType = item.split(':')[0]
        mediaType = switch hackType
          when 'cnxmodule' then 'application/vnd.org.cnx.module'
          when 'cnxcollection' then 'application/vnd.org.cnx.collection'
          else throw 'BUG:TYPE_NOT_FOUND'
        item = {id: item, mediaType: mediaType, title: 'FOLDER_HACK_TITLE'}

      model = Models.ALL_CONTENT.get item.id
      models.push model if model
    @contents.reset(models)

    delete obj.body
    obj

  Models_Folder_initialize = Models.Folder::initialize
  Models.Folder::initialize = (obj={}) ->
    Models_Folder_initialize.apply(@, arguments)

    for item in obj.body or []
      Type = MEDIA_TYPES.get(item.mediaType)
      model = new Type(item)
      @contents.add model

    # Events on the collection "bubble up" as a change event so
    # "Save" knows this item is "dirty"
    @contents.on 'all', =>
      args = _.toArray arguments
      json = []
      @contents.each (item) -> json.push item.id
      @set 'body', json


  AtcWorkspace = Models.DeferrableCollection.extend
    url: WORKSPACE_URL
    # Workspace comes in with the following format:
    #
    #     [
    #       {mediaType: 'application/vnd.org.cnx.folder', id: 'cnxfolder:123', title: 'Some Title', ...} ...],
    #       {mediaType: 'application/vnd.org.cnx.module', id: 'cnxmodule:123', title: 'Some Title', ...} ...],
    #       {mediaType: 'application/vnd.org.cnx.collection', id: 'cnxcollection:123', title: 'Some Title', ...} ...],
    #     ]
    #
    # Convert that to models (if they are not already loaded).
    parse: (results) ->
      # Rewrite the `mediaType` so it matches what the bookish editor expects.
      results = for item in results
        # **FIXME:** Only instantiate the Model if it does not already exist in `Models.ALL_CONTENT`
        ContentType = MEDIA_TYPES.get(item.mediaType)
        model = new ContentType(item)
        model

      results

    # If new content is created/loaded, add it to the workspace
    initialize: ->
      # If the workspace is updated make sure `Models.ALL_CONTENT` has the new content
      @on 'add', (model) => Models.ALL_CONTENT.add model
      @on 'reset', (collection) => Models.ALL_CONTENT.add @models

      # If a model is added to `Models.ALL_CONTENT` ensure it shows up in the workspace
      @listenTo Models.ALL_CONTENT, 'add', (model) =>
        @add model

  # Replace the default workspace (`Models.ALL_CONTENT`) with this workspace.
  Models.WORKSPACE = new AtcWorkspace()

  resetDesktop = ->
    # Clear out all the content and refetch the workspace
    Models.ALL_CONTENT.reset()
    Models.WORKSPACE.fetch()

    # Begin listening to route changes
    # and load the initial views based on the URL.
    if not Backbone.History.started
      Controller.start()
    Backbone.history.navigate('workspace')


  # Refetch the workspace when the user Signs In/Out.
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

