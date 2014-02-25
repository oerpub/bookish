# The controller is used by various views to change the UI (what is being edited).
# For example, clicking on a piece of content or a book will replace the workspace list with
# a large area for editing the document

# There is a cyclic dependency between this and various views (`->` means "depends on"):
# controller -> layout -> WorkspaceView -> WorkspaceItemView -> controller (because clicking an item will begin editing)
define [
  'underscore'
  'marionette'
  'cs!collections/content'
  'cs!models/content/toc-node'
  'cs!views/layouts/workspace'
], (_, Marionette, allContent, TocNode, WorkspaceLayout) ->


  # Only reason to extend Backbone.Router is to get the @navigate method
  return new class AppController extends Marionette.AppRouter

    setRootNode: (@rootNode) ->

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
      @layout.menu.show(menuLayout) if menuLayout and not @layout.menu.currentView

    # There is a cyclic dependency between the controller and the ToC tree because
    # the user can click an item in the ToC to `goEdit`.
    _showWorkspacePane: (SidebarView) ->
      if not @layout.workspace.currentView
        @layout.workspace.show(new SidebarView {model:@rootNode})


    # Show Workspace
    # -------
    # Show the workspace listing and update the URL
    goWorkspace: () ->
      # To prevent cyclic dependencies, load the views once the app has loaded.
      require [
        'cs!views/layouts/workspace/menu'
        'cs!views/layouts/workspace/bookshelf'
        'cs!views/layouts/workspace/table-of-contents'
        'cs!views/workspace/content/search-results'
        ], (menuLayout, BookshelfView, TocView, SearchResultsView) =>

        @_ensureLayout(menuLayout)

        # Load the sidebar
        allContent.load()
        .fail(() => alert 'Problem loading workspace. Please refresh and try again')
        .done () =>
          #@_showWorkspacePane(SidebarView)
          @_showWorkspacePane(BookshelfView)

          # Find the first TocNode and show that in the Toc panel
          firstBook = _.find allContent.without(this.model), (m) ->
            m instanceof TocNode
          tocView = new TocView
            model: firstBook

          @layout.sidebar.show(tocView)
          #@layout.sidebar.close()
          @layout.content.show(new SearchResultsView {collection:allContent})

          # Update the URL
          @trigger 'navigate', 'workspace'


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
        'cs!views/layouts/workspace/bookshelf'
        'cs!views/layouts/workspace/table-of-contents'
        ], (menuLayout, BookshelfView, TocView) =>

        @_ensureLayout(menuLayout)

        allContent.load()
        .fail(() => alert 'Problem loading workspace. Please refresh and try again')
        .done () =>
          if typeof model is 'string'
            [model, contextModel] = model.split('|')
            # Un-escape the `model.id` because a piece of content may have `/` in it (github uses these)
            model = decodeURI(model)
            model = allContent.get(model)

            if contextModel
              # Un-escape the `model.id` because a piece of content may have `/` in it (github uses these)
              contextModel = decodeURI(contextModel)
              contextModel = allContent.get(contextModel)

          # Redirect to workspace if model does not exist
          if not model
            @goWorkspace()
          else
            # reset the old highlight state if there was one

            @_currentModel?.set('_selected', false)
            @_currentContext?.set('_selected', false)

            # these are needed on the next render as a pointers to things
            # Always use the dereferenced node because content can be in more than one book
            @_currentModel = model.dereferencePointer?() or model
            @_currentContext = contextModel?.dereferencePointer?() or contextModel

            # this is needed right now to render the workspace
            @_currentContext?.set('_selected', true)

            # Always show the workspace pane
            @_showWorkspacePane(BookshelfView)

            # set more granular file selected flags to be used in ToC
            @_currentModel.set('_selected', true) # Need to set it on the dereferenced pointer

            # Force the sidebar if a contextModel is passed in
            @layout.sidebar.reset()

            if contextModel
              # Only change the view if there is nothing there or if the model differs
              if !@layout.sidebar.currentView or @layout.sidebar.currentView.model != contextModel
                contextView = new TocView
                  model: contextModel

                @layout.sidebar.show(contextView)
                contextView.maximize()
                
            # Some models do not change the sidebar because they cannot contain children (like Module)
            else if model.getChildren
              # Only change the view if there is nothing there or if the model differs
              if !@layout.sidebar.currentView or @layout.sidebar.currentView.model != model
                modelView = new TocView
                  model: model
                @layout.sidebar.show(modelView)
                modelView.maximize()

            @layout.content.reset()

            model.contentView((view) => if view then @layout.content.show(view)) if model.contentView

            # Load the menu's toolbar
            if model.toolbarView
              model.toolbarView((view) => if view then @layout.menu.currentView.showToolbar(view))
            else @layout.menu.currentView.showToolbar()

            # URL-escape the `model.id` because a piece of content may have `/` in it (github uses these)
            contextPath = ''
            contextPath = "|#{encodeURI(contextModel.id or contextModel.cid)}" if contextModel

            # Update the URL
            @trigger 'navigate', "edit/#{encodeURI(model.id or model.cid)}#{contextPath}"
