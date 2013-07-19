require.config
  paths:
    mock: '../test/data'
    underscore: './libs/lodash'

define [
  'underscore'
  'jquery'
  'cs!./all-mock-data'
  'mockjax'
], (_, $, allMocks) ->

  counter = 0
  memoryRepo = {}
  memoryResources = {}

  # `allMocks` contains a `.content` and optionally a `.resources`
  # - `.content` is an array of objects that represent the content (Module, Book, Folder)
  #              to be added to the workspace
  # - `.resources` is an object whose key is a hash id and value is a binary string
  #                representing things like images, java applets, etc.
  _.each allMocks.content, (fields) -> memoryRepo[fields.id] = fields
  _.each (_.pairs allMocks.resources), (hash, bytes) -> memoryResources[hash] = bytes




  # GET session
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
      # Generate a response using the in-memory JSON stored in `memoryRepo`
      ret = []
      json = _.each (_.pairs memoryRepo), (pair) ->
        [id, attributes] = pair
        ret.push _.pick attributes, 'id', 'mediaType', 'title'

      @responseText = ret

  # GET/PUT/POST for `/content*`

  $.mockjax
    type: 'GET'
    dataType: 'json'
    url: /^\/(content|module|folder|collection)\/(.+)$/
    urlParams: ['HACK_PREFIX_DISCARDED', 'id']
    response: (settings) ->
      id = settings.urlParams['id']

      if id of memoryRepo
        res = memoryRepo[id]
        @responseText = JSON.stringify(res)
      else
        console.error "BUG! Asked for a non-existent piece of content with id=#{id}"
        @status = 404

  $.mockjax
    type: 'PUT'
    url: /^\/(content|module|folder|collection)\/(.+)$/
    urlParams: ['HACK_PREFIX_DISCARDED', 'id']
    response: (settings) ->
      id = settings.urlParams['id']
      if id of memoryRepo
        memoryRepo[id] = JSON.parse(settings.data)
        # TODO: Validation goes here
        res = memoryRepo[id]
        @responseText = JSON.stringify(res)
      else
        @status = 403

  $.mockjax
    type: 'POST'
    url: /^\/(content|module|folder|collection)\/$/
    urlParams: ['HACK_PREFIX_DISCARDED']
    response: (settings) ->
      id = "mock-id-#{counter++}"

      json = JSON.parse(settings.data)
      json.id = id
      memoryRepo[id] = json

      res = memoryRepo[id]
      @responseText = JSON.stringify(res)


  # Load the actual app
  require(['cs!../scripts/config'])
