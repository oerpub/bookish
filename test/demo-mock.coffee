require.config
  paths:
    mock: '../test/data'
    underscore: './libs/lodash'

define [
  'underscore'
  'jquery'
  'mockjax'
], (_, $) ->

  # Listed below are various content generators.
  # Feel free to comment out ones you do not want to load for testing purposes
  DEPENDENCIES = [
    'cs!mock/module-simple'
    'cs!mock/book-empty'
    'cs!mock/book-simple'

    'cs!mock/book-override-title'
    'cs!mock/book-big' # Adds a TON of modules into the workspace
    'cs!mock/book-tree-simple'
    # 'cs!mock/book-tree-big'

    'cs!mock/folder-empty'
    'cs!mock/folder-simple'
    'cs!mock/folder-big' # Uses modules in `book-big`
    'cs!mock/folder-mixed'

    # 'cs!mock/module-image'
    'cs!mock/modules-cycle'


    'cs!mock/module-metadata'
    'cs!mock/book-metadata'
  ]

  require DEPENDENCIES, () ->
    counter = 0
    memoryContent = {}
    memoryResources = {}

    # Each dependency contains a `.content` and optionally a `.resources`
    # - `.content` is an array of objects that represent the content (Module, Book, Folder)
    #              to be added to the workspace
    # - `.resources` is an object whose key is a hash id and value is a binary string
    #                representing things like images, java applets, etc.
    _.each arguments, (dep) ->
      _.each dep.content, (fields) -> memoryContent[fields.id] = fields
      _.each (_.pairs dep.resources), (hash, bytes) -> memoryResources[hash] = bytes




    # GET

    $.mockjax
      url: '/me'
      proxy: 'data/me.json'

    $.mockjax
      url: '/logging'
      type: 'POST'
      response: (settings) ->
        return 'OK'

    $.mockjax
      type: 'GET'
      dataType: 'json'
      url: '/workspace'
      response: (settings) ->
        ret = []
        json = _.each (_.pairs memoryContent), (pair) ->
          [id, attributes] = pair
          ret.push _.pick attributes, 'id', 'mediaType', 'title'

        @responseText = ret

    $.mockjax
      type: 'GET'
      dataType: 'json'
      url: /^\/(content|module|folder|collection)\/(.+)$/
      urlParams: ['HACK_PREFIX_DISCARDED', 'id']
      response: (settings) ->
        id = settings.urlParams['id']

        if id of memoryContent
          res = memoryContent[id]
          @responseText = JSON.stringify(res)
        else
          @status = 404

    $.mockjax
      type: 'PUT'
      url: /^\/(content|module|folder|collection)\/(.+)$/
      urlParams: ['HACK_PREFIX_DISCARDED', 'id']
      response: (settings) ->
        id = settings.urlParams['id']
        if id of memoryContent
          memoryContent[id] = JSON.parse(settings.data)
          # TODO: Validation goes here

          # Update the lastModified time because they saved
          memoryContent[id].dateLastModifiedUTC = (new Date()).toJSON()

          res = memoryContent[id]
          @responseText = JSON.stringify(res)
        else
          @status = 403

    $.mockjax
      type: 'POST'
      url: /^\/(content|module|folder|collection)\/$/
      urlParams: ['HACK_PREFIX_DISCARDED']
      response: (settings) ->
        id = "new-mock-id-#{counter++}"

        json = JSON.parse(settings.data)
        json.id = id
        memoryContent[id] = json

        # Update the lastModified time **and** created time
        now = (new Date()).toJSON()
        memoryContent[id].dateCreatedUTC = now
        memoryContent[id].dateLastModifiedUTC = now

        res = memoryContent[id]
        @responseText = JSON.stringify(res)


    # Load the actual app
    require(['cs!../scripts/config'])
