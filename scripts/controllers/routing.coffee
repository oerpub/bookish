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
    _showWorkspacePane: (SidebarView) ->
      @layout.workspace.show(new SidebarView {collection:allContent})


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

            if not contextModel
              console.log 'something has gone wonky'

            # resset the old highligh state if there was one
            @currentModel?.set('selected', false)
            @currentContext?.set('selected', false)

            # these are needed on the next render as a pointers to things 
            @currentModel = model
            @currentContext = contextModel

            # this is needed right now to render the workspace
            contextModel.set('selected', true)

            # Always show the workspace pane
            @_showWorkspacePane(SidebarView, model)

            # set more granular file selected flags to be used in ToC
            model.set('selected', true)

            if !@layout.sidebar.currentView or @layout.sidebar.currentView.model != contextModel
              contextView = new SidebarView
                model: contextModel

              @layout.sidebar.show(contextView)
              contextView.maximize()

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
