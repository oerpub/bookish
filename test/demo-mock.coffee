define [
  'jquery'
  'mockjax'
], ($) ->


  ID = 0
  MEMORY_REPO = {}

  # GET

  $.mockjax
    url: '/me'
    proxy: 'data/me.json'

  $.mockjax
    url: '/workspace'
    proxy: 'data/content.json'

  $.mockjax (settings) ->
    # url: '/api/content/<id>'
    id = settings.url.match(/\/api\/content\/(.+)$/);
    id = id?[1] or null

    switch settings.type
      when 'GET'
        # First check the in-memory content
        return MEMORY_REPO[id] if MEMORY_REPO[id]

        return {proxy: 'data/content/' + id + '.json'}

      when 'PUT'
        MEMORY_REPO[id] = JSON.parse(settings.data)
        return MEMORY_REPO[id]

  # POST

  $.mockjax
    url: '/api/content/'
    type: 'POST'
    response: (settings) ->
      id = ID++
      MEMORY_REPO[id] = JSON.parse(settings.data)
      MEMORY_REPO[id].id = "${id}"
      return MEMORY_REPO[id]


  # Load the actual app
  require(['cs!../scripts/config'])
