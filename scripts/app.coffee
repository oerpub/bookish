define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!session'
], ($, _, Backbone, Marionette, session) ->

  app = new Marionette.Application()

  app.root = ''

  app.addRegions
    main: '#main'

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
          if href then router.navigate(href, {trigger: true})

      Backbone.history.start
        #pushState: true
        root: app.root

  return app
