define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
], ($, _, Backbone, Marionette) ->

  app = new Marionette.Application()

  app.on 'start', (options) ->
    # Load router
    require ['cs!routers/router'], (router) ->
      $(document).on 'click', 'a:not([data-bypass])', (e) ->
        external = new RegExp('^((f|ht)tps?:)?//')
        href = $(@).attr('href')

        e.preventDefault()

        if external.test(href)
          window.open(href, '_blank')
        else
          router.navigate(href, {trigger: true})

      Backbone.history.start({pushState: true})

  return app
