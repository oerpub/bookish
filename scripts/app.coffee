define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!session'
  'less!styles/main.less'
], ($, _, Backbone, Marionette, session) ->

  app = new Marionette.Application()

  app.root = ''

  app.addRegions
    main: '#main'

  app.on 'start', (options) ->
    # Load router (it registers globally to Backbone.history)
    require ['cs!controllers/routing', 'cs!routers/router'], (controller) =>
      # set the main div for all the layouts
      controller.main = @main

      if not Backbone.History.started
        Backbone.history.start
          #pushState: true
          root: app.root

    session.login()
  return app
