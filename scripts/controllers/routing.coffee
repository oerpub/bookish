define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!app'
  #'cs!views/layouts/workspace'
], ($, _, Backbone, Marionette, app, workspaceLayout) ->

  return new (Marionette.Controller.extend
    # Show Workspace
    # -------
    # Shows the workspace listing and updates the URL
    workspace: ->
      console.log 'workspace'

    # Edit existing content
    # -------
    # Calling this method directly will start editing an existing piece of content
    # and will update the URL.
    editModelId: (id) ->
  )()
