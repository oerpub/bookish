define [
  'backbone'
  'marionette'
  'cs!session'
  'cs!collections/content'
  'cs!collections/media-types'
  'cs!models/workspace-root'
  'cs!models/content/book'
  'cs!models/content/book-toc-node'
  'cs!models/content/folder'
  'cs!models/content/module'
  'less!styles/main.less'
], (Backbone, Marionette, session, allContent, mediaTypes, workspaceRoot, Book, BookTocNode, Folder, Module) ->

  app = new Marionette.Application()

  app.root = ''

  app.addRegions
    main: '#main'

  app.on 'start', (options) ->

    # Register all the mediaTypes used
    mediaTypes.add Book
    mediaTypes.add BookTocNode
    mediaTypes.add Folder
    mediaTypes.add Module


    # Load router (it registers globally to Backbone.history)
    require ['cs!controllers/routing', 'cs!routers/router'], (controller) =>
      # set the main div for all the layouts
      controller.main = @main

      controller.setRootNode(workspaceRoot)

      # The controller fires a navigate event, the app then updates the url
      # as it sees fit.
      controller.on 'navigate', (route) -> controller.navigate route

      if not Backbone.History.started
        Backbone.history.start
          #pushState: true
          root: app.root

    session.login()
  return app
