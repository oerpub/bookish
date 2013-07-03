define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!app'
  'cs!collections/content'
  'cs!views/layouts/workspace'
  'less!styles/main.less'
], ($, _, Backbone, Marionette, app, content, WorkspaceLayout) ->

  return new class Router extends Marionette.AppRouter
    # Show Workspace
    # -------
    # Show the workspace listing and update the URL
    workspace: () ->
      if not @layout
        @layout = new WorkspaceLayout()
        app.main.show(@layout)
      else
        # load default views
        @layout.showViews()

    # Edit existing content
    # -------
    # Start editing an existing piece of content and update the URL.
    edit: (model) ->
      if typeof model is 'string'
        model = content.get(model)

      # Redirect to workspace if model does not exist
      if not model
        require ['cs!routers/router'], (router) ->
          router.navigate('/', {trigger: true, replace: true});

      if not @layout
        @layout = new WorkspaceLayout({model: model})
        app.main.show(@layout)
      else
        # load editor views
        @layout.showViews({model: model})
