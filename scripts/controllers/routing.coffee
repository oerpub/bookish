# The controller is used by various views to change the UI (what is being edited).
# For example, clicking on a piece of content or a book will replace the workspace list with
# a large area for editing the document

# There is a cyclic dependency between this and various views (`->` means "depends on"):
# controller -> layout -> WorkspaceView -> WorkspaceItemView -> controller (because clicking an item will begin editing)
define ['marionette'], (Marionette) ->

  # Only reason to extend Backbone.Router is to get the @navigate method
  return new class AppController extends Marionette.AppRouter
    # Show Workspace
    # -------
    # Show the workspace listing and update the URL
    goWorkspace: () ->
      # To prevent cyclic dependencies, load the views once the app has loaded.
      require ['cs!views/layouts/workspace'], (WorkspaceLayout) =>
        if not @layout
          @layout = new WorkspaceLayout()
          @main.show(@layout)
        else
          # load default views
          @layout.showViews()
        # Update the URL without triggering the router
        @navigate('workspace')

    # Edit existing content
    # -------
    # Start editing an existing piece of content and update the URL.
    goEdit: (model) ->
      # To prevent cyclic dependencies, load the views once the app has loaded.
      require ['cs!views/layouts/workspace', 'cs!collections/content'], (WorkspaceLayout, allContent) =>

        if typeof model is 'string'
          model = allContent.get(model)

        # Redirect to workspace if model does not exist
        if not model
          @goWorkspace()
        else
          if not @layout
            @layout = new WorkspaceLayout({model: model})
            @main.show(@layout)

          # load editor views
          @layout.showViews({model: model})

          # Update the URL without triggering the router
          @navigate("edit/#{model.id or model.cid}")
