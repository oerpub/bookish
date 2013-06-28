define [
  'jquery'
  'mockjax'
], ($) ->

  # GET

  $.mockjax
    url: '/api/me'
    proxy: 'data/me.json'

  $.mockjax
    url: '/api/content'
    proxy: 'data/content.json'

  $.mockjax (settings) ->
    # url: '/api/content/<id>'
    id = settings.url.match(/\/api\/content\/(.*)$/);
    if id
      return {proxy: 'data/content/' + id[1] + '.json'}

  # POST
  
  $.mockjax
    url: '/logging'
    type: 'post'

  # Load the actual app
  require(['cs!../scripts/config'])
