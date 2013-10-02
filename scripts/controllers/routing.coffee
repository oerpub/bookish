# The controller is used by various views to change the UI (what is being edited).
# For example, clicking on a piece of content or a book will replace the workspace list with
# a large area for editing the document

# There is a cyclic dependency between this and various views (`->` means "depends on"):
# controller -> layout -> WorkspaceView -> WorkspaceItemView -> controller (because clicking an item will begin editing)
define [
  'marionette'
  'cs!collections/content'
  'cs!views/layouts/workspace'
  ], (Marionette, allContent, WorkspaceLayout) ->


  # Only reason to extend Backbone.Router is to get the @navigate method
  return new class AppController extends Marionette.AppRouter

    # For all the views ensure there is a layout.
    # There is a cyclic dependency between the controller and `menuLayout`
    # because `menuLayout` has a "Home" button.
    _ensureLayout: (menuLayout) ->
      # TODO: This can be moved into the initialize once the
      # WorkspaceLayout constructor does not trigger logging POST events
      if not @layout or not @layout.menu
        @layout = new WorkspaceLayout()
        @main.show(@layout)

      # Make sure the menu is loaded
      # TODO: This can be removed if the "Home" button (and click event) are moved into this layout
      @layout.menu.show(menuLayout) if not @layout.menu.currentView

    # There is a cyclic dependency between the controller and the ToC tree because
    # the user can click an item in the ToC to `goEdit`.
    _showWorkspacePane: (SidebarView, currentFile) ->

      focusBook = null
      if currentFile
        for book in allContent.models
          focusBook = book if book.hasChild?(currentFile.id)

      @layout.workspace.show(new SidebarView {collection:allContent, currentFile: focusBook})


    # Show Workspace
    # -------
    # Show the workspace listing and update the URL
    goWorkspace: () ->
      # To prevent cyclic dependencies, load the views once the app has loaded.
      require [
        'cs!views/layouts/workspace/menu'
        'cs!views/layouts/workspace/sidebar'
        'cs!views/workspace/content/search-results'
        ], (menuLayout, SidebarView, SearchResultsView) =>

        @_ensureLayout(menuLayout)

        # Load the sidebar
        allContent.load()
        .fail(() => alert 'Problem loading workspace. Please refresh and try again')
        .done () =>
          @_showWorkspacePane(SidebarView)
          @layout.sidebar.close()
          @layout.content.show(new SearchResultsView {collection:allContent})

          # Update the URL without triggering the router
          @navigate('workspace')


    # Edit existing content
    # -------
    # Start editing an existing piece of content and update the URL.
    #
    # An optional `contextModel` can also be sent which will change the side pane
    # which shows the current Book/Folder being edited.
    #
    # Also, the route is updated to include this context.
    goEdit: (model, contextModel=null) ->
      # To prevent cyclic dependencies, load the views once the app has loaded.
      require [
        'cs!views/layouts/workspace/menu'
        'cs!views/layouts/workspace/sidebar'
        ], (menuLayout, SidebarView) =>

        @_ensureLayout(menuLayout)

        allContent.load()
        .fail(() => alert 'Problem loading workspace. Please refresh and try again')
        .done () =>
          if typeof model is 'string'
            [model, contextModel] = model.split('|')
            # Un-escape the `model.id` because a piece of content may have `/` in it (github uses these)
            model = decodeURIComponent(model)
            model = allContent.get(model)


            if contextModel
              # Un-escape the `model.id` because a piece of content may have `/` in it (github uses these)
              contextModel = decodeURIComponent(contextModel)
              contextModel = allContent.get(contextModel)

          # Redirect to workspace if model does not exist
          if not model
            @goWorkspace()
          else
            # Always show the workspace pane
            @_showWorkspacePane(SidebarView, model)

            # load editor views

            # Force the sidebar if a contextModel is passed in
            if contextModel
              contextView = new SidebarView
                model: contextModel
                currentFile: model

              @layout.sidebar.show(contextView)
              contextView.maximize()
            # Some models do not change the sidebar because they cannot contain children (like Module)
            else if model.getChildren
              modelView = new SidebarView
                model: model
                currentFile: model

              @layout.sidebar.show(modelView)
              modelView.maximize()

            model.contentView((view) => if view then @layout.content.show(view)) if model.contentView

            # Load the menu's toolbar
            if model.toolbarView
              model.toolbarView((view) => if view then @layout.menu.currentView.showToolbar(view))
            else @layout.menu.currentView.showToolbar()

            # URL-escape the `model.id` because a piece of content may have `/` in it (github uses these)
            contextPath = ''
            contextPath = "|#{encodeURIComponent(contextModel.id or contextModel.cid)}" if contextModel

            # Update the URL without triggering the router
            @navigate("edit/#{encodeURIComponent(model.id or model.cid)}#{contextPath}")
