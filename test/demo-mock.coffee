define [
  'jquery'
  'mockjax'
], ($) ->

  counter = 0
  memoryRepo = {}

  # GET

  $.mockjax
    url: '/me'
    proxy: 'data/me.json'

  $.mockjax
    url: '/workspace'
    proxy: 'data/content.json'

  $.mockjax
    url: '/logging'
    type: 'POST'
    response: (settings) ->
      return 'OK'

  $.mockjax (settings) ->
    # url: '/content/<id>'
    id = settings.url.match(/\/(content|module|folder|collection)\/(.*)$/)
    id = id?[2] or null

    switch settings.type
      when 'GET'
        # First check the in-memory content
        return memoryRepo[id] if memoryRepo[id]

        return {proxy: 'data/content/' + id + '.json'}

      when 'PUT'
        memoryRepo[id] = JSON.parse(settings.data)
        return memoryRepo[id]

      when 'POST'
        id = counter++
        memoryRepo[id] = JSON.parse(settings.data)
        memoryRepo[id].id = "${id}"
        return memoryRepo[id]

  # Load the actual app
  require(['cs!../scripts/config'])
