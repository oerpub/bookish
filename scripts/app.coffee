define [
  'backbone'
  'marionette'
  'cs!session'
  'cs!collections/media-types'
  'cs!models/content/book'
  'cs!models/content/folder'
  'cs!models/content/module'
  'less!styles/main.less'
], (Backbone, Marionette, session, mediaTypes, Book, Folder, Module) ->

  app = new Marionette.Application()

  app.root = ''

  app.addRegions
    main: '#main'

  app.on 'start', (options) ->

    # Register all the mediaTypes used
    mediaTypes.add Book
    mediaTypes.add Folder
    mediaTypes.add Module


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
