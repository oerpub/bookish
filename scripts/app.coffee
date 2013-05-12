define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!session'
  'cs!views/layouts/app'
], ($, _, Backbone, Marionette, session, appLayout) ->

  app = new Marionette.Application()

  app.root = ''

  app.addRegions
    body: 'body'

  app.on 'start', (options) ->
    # Load layout
    console.log appLayout
    app.body.show(appLayout)

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

      Backbone.history.start
        pushState: true
        root: app.root

  return app
