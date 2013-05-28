define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!app'
  'cs!collections/content'
  'cs!views/layouts/workspace'
  'cs!views/layouts/editor'
  'less!styles/main.less'
], ($, _, Backbone, Marionette, app, content, workspaceLayout, EditorLayout) ->

  return new (Marionette.Controller.extend
    # Show Workspace
    # -------
    # Show the workspace listing and update the URL
    workspace: ->
      app.main.show(workspaceLayout)

    # Edit existing content
    # -------
    # Start editing an existing piece of content and update the URL.
    edit: (model) ->
      if typeof model is 'string'
        model = content.get(model)

      if model
        app.main.show(new EditorLayout(model))
      else
        # Redirect to workspace if model does not exist
        require ['cs!routers/router'], (router) ->
          router.navigate('/', {trigger: true, replace: true});
  )()
