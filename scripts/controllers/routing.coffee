# Routing Controller
# =======
# Changes all the regions on the page to begin editing a new/existing
# piece of content.
#
# If another part of the code wants to create/edit content
# it should call these methods instead of changing the URL directly.
# (depending on the browser the URLs could start with a hash so anchor links won't work)
#
# Methods on this object can be called directly and will update the URL.

define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/layouts/workspace'
], ($, _, Backbone, Marionette, workspaceLayout) ->

  return new (Marionette.Controller.extend
    # Show Workspace
    # -------
    # Shows the workspace listing and updates the URL
    workspace: ->
      workspaceLayout.render()

    # Edit existing content
    # -------
    # Calling this method directly will start editing an existing piece of content
    # and will update the URL.
    editModelId: (id) ->
      console.log 'editModelId'
      workspaceLayout.render()
  )()
