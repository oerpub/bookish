define [
  'jquery'
  'mockjax'
], ($) ->

  $.mockjax
    url: '/api/me'
    proxy: 'data/me.json'

  $.mockjax
    url: '/api/content'
    proxy: 'data/content.json'

  $.mockjax (settings) ->
    # url: '/content/<id>'
    id = settings.url.match(/\/content\/(.*)$/);
    if id
      return {proxy: 'data/content/' + id[1] + '.json'}

  # Load the actual app
  require(['cs!../scripts/config'])
