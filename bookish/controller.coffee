# <!-- Copyright (c) 2013 Rice University
#
# This software is subject to the provisions of the GNU AFFERO GENERAL PUBLIC LICENSE Version 3.0 (AGPL).
# See LICENSE.txt for details. -->

# Page Controllers
# =======
#
# This module sets up page regions (ie header, footer, sidebar, etc),
# route listeners, and updates the URL and DOM with the correct views
#
# This makes it easier in other parts of the code to 'Go back to the Workspace'
# or "Edit this content" when clicking on a link.
define [
  'jquery'
  'backbone'
  'marionette'
  'bookish/media-types'
  'bookish/auth'
  'bookish/models'
  # There is a cyclic dependency between views and controllers
  # so we use the `exports` module to get around that problem.
  'bookish/views'
  'hbs!bookish/layouts/main'
  'hbs!bookish/layouts/content'
  'hbs!bookish/layouts/workspace'
  'exports'
  'i18n!bookish/nls/strings'
], (jQuery, Backbone, Marionette, MEDIA_TYPES, Auth, Models, Views, LAYOUT_MAIN, LAYOUT_CONTENT, LAYOUT_WORKSPACE, exports, __) ->

  mainRegion = new Marionette.Region
    el: '#main'


  # Use a custom region manager so CSS3 transitions can be triggered
  HidingRegion = Marionette.Region.extend
    onShow: ->  @$el.removeClass 'hidden'
    onClose: -> @ensureEl(); @$el.addClass 'hidden'

  # Layouts
  # =======
  # The `MainLayout` contains all areas of the page that do not change
  MainLayout = Marionette.Layout.extend
    template: LAYOUT_MAIN
    regions:
      home:         '#layout-main-home'
      add:          '#layout-main-add'
      toolbar:      '#layout-main-toolbar'
      auth:         '#layout-main-auth'
      # The sidebar and main area will get a 'hidden' class when hiding
      # so CSS transitions can be applied.
      sidebar:      '#layout-main-sidebar'
      area:         {selector: '#layout-main-area', regionType: HidingRegion}
  mainLayout = new MainLayout()
  # Keep the regions so views can just update the regions they need
  mainAdd = mainLayout.add
  mainToolbar = mainLayout.toolbar
  mainSidebar = mainLayout.sidebar
  mainArea = mainLayout.area

  # Used when editing a single piece of content.
  # Contains additional areas for editing metadata using separate views
  ContentLayout = Marionette.Layout.extend
    template: LAYOUT_CONTENT
    regions:
      title:        '#layout-title'
      body:         '#layout-body'
      # Specific to content
      metadata:     '#layout-metadata'
      roles:        '#layout-roles'
  contentLayout = new ContentLayout()


  # Main Controller
  # =======
  # Changes all the regions on the page to begin editing a new/existing
  # piece of content.
  #
  # If another part of the code wants to create/edit content
  # it should call these methods instead of changing the URL directly.
  # (depending on the browser the URLs could start with a hash so anchor links won't work)
  #
  # Methods on this object can be called directly and will update the URL.
  mainController =

    # Begin monitoring URL changes and match the current route
    # In here so App can call it once it has completed loading
    start: ->
      mainRegion.show mainLayout
      mainLayout.auth.show new Views.AuthView {model: Auth}

      mainLayout.home.ensureEl() # Not sure why this particular region needs this...
      mainLayout.home.$el.on 'click', => @workspace()


      # Hide the regions if they are not being used
      mainArea.onClose()
      # Start URL Routing if it has not already started
      Backbone.history.start() if not Backbone.History.started

    # Provide the main region that this controller uses.
    # Useful for applications that want to extend this editor.
    getRegion: -> mainRegion

    # Give others access to the main layout so they can change pieces of it
    mainLayout: mainLayout

    # Show Workspace
    # -------
    # Shows the workspace listing and updates the URL
    workspace: ->
      # Always scroll to the top of the page
      window.scrollTo(0, 0)

      mainToolbar.close()
      # List the workspace.
      workspace = new Models.FilteredCollection null, {collection: Models.WORKSPACE}

      # Allow filtering the workspace by searching in the `SearchBoxView`
      view = new Views.SearchBoxView {model: workspace}
      mainToolbar.show view

      view = new Views.SearchResultsView {collection: workspace}
      mainArea.show view

      # Add the "Add" button
      mainAdd.show new Views.AddView
        collection: MEDIA_TYPES.asCollection()

      workspaceTree = new Models.WorkspaceTree()
      view = new Views.BookEditView {model: workspaceTree}
      mainSidebar.show view

      # Update the URL when the workspace is fetched and loaded
      Models.WORKSPACE.loaded().done =>
        workspaceTree.loaded().done =>
          # Update the URL
          Backbone.history.navigate 'workspace'

    # Edit existing content
    # -------
    # Calling this method directly will start editing an existing piece of content
    # and will update the URL.
    editModelId: (id) ->
      model = Models.ALL_CONTENT.get id
      # If we cannot find a piece of content redirect to the workspace
      # (maybe the user refreshed the page)
      return @workspace() if not model
      @editModel model

    # Edit a piece of content.
    # Called when a link is clicked in the workspace list or in a search result window
    #
    # Dispatches based on the contents' `mediaType`
    editModel: (model) ->
      throw 'BUG: model.mediaType does not exist' if not model.mediaType
      model.editAction()

    # Edit a book in the main area
    editBook: (book) ->
      # Always scroll to the top of the page
      window.scrollTo(0, 0)

      # List the contents of the book.
      workspace = new Models.FilteredCollection null, {collection: book.manifest}

      # Allow filtering the workspace by searching in the `SearchBoxView`
      view = new Views.SearchBoxView {model: workspace}
      mainToolbar.show view

      view = new Views.SearchResultsView {collection: workspace}
      mainArea.show view

      # Add the "Add" button
      mainAdd.show new Views.AddView
        collection: MEDIA_TYPES.asCollection()
        itemViewOptions:
          addToContext: (content) -> book.addChild(content)

      view = new Views.BookEditView {model: book}
      mainSidebar.show view

      # Update the URL when the workspace is fetched and loaded
      book.loaded().done =>
        # Update the URL
        Backbone.history.navigate "content/#{book.id}"

    # Edit a folder in the sidebar
    editFolder: (folder) ->
      # Always scroll to the top of the page
      window.scrollTo(0, 0)

      # List the contents of the folder.
      workspace = new Models.FilteredCollection null, {collection: folder.children()}

      # Allow filtering the workspace by searching in the `SearchBoxView`
      view = new Views.SearchBoxView {model: workspace}
      mainToolbar.show view

      view = new Views.SearchResultsView {collection: workspace}
      mainArea.show view

      # Add the "Add" button
      mainAdd.show new Views.AddView
        collection: MEDIA_TYPES.asCollection()
        # Define what happens when one of the Add Items is clicked
        itemViewOptions:
          addToContext: (content) -> folder.addChild content

      # Do not change the `mainSidebar`

      # Update the URL when the workspace is fetched and loaded
      folder.loaded().done =>
        # Update the URL
        Backbone.history.navigate "content/#{folder.id}"

    # Edit a piece of HTML content
    editContent: (content) ->
      # Always scroll to the top of the page
      window.scrollTo(0, 0)

      # Bind Metadata Dialogs
      # -------
      mainArea.show contentLayout

      # Load the various views:
      #
      # - The Aloha toolbar
      # - The editable title at the top of the document under the toolbar
      # - The metadata/roles accordion
      # - The main editable content area

      # Wrap each 'tab' in the accordion with a Save/Cancel dialog
      configAccordionDialog = (region, view) ->
        dialog = new Views.DialogWrapper {view: view}
        region.show dialog
        # When save/cancel are clicked collapse the accordion
        dialog.on 'saved',     => region.$el.parent().collapse 'hide'
        dialog.on 'cancelled', => region.$el.parent().collapse 'hide'

      # Set up the metadata dialog
      configAccordionDialog contentLayout.metadata, new Views.MetadataEditView {model: content}
      configAccordionDialog contentLayout.roles,    new Views.RolesEditView {model: content}

      view = new Views.ContentToolbarView(model: content)
      mainToolbar.show view

      view = new Views.TitleEditView(model: content)
      contentLayout.title.show view

      # Enable the tooltip letting the user know to edit
      contentLayout.title.$el.popover
        trigger: 'hover'
        placement: 'right'
        content: __('Click to change title')

      view = new Views.ContentEditView(model: content)
      contentLayout.body.show view


      content.loaded().then =>
        # Update the URL
        Backbone.history.navigate "content/#{content.get 'id'}"

  # Bind Routes
  # =======
  ContentRouter = Marionette.AppRouter.extend
    controller: mainController
    appRoutes:
      '':             'workspace' # Show the workspace list of content
      'workspace':    'workspace'
      'content/:id':  'editModelId' # Edit an existing piece of content

  # Attach mediaType edit views
  # -------
  # Add the 2 basic Media Types already defined in `Models`.
  Models.BaseContent::editAction = -> mainController.editContent @
  Models.BaseBook::editAction =    -> mainController.editBook @
  Models.Folder::editAction =      -> mainController.editFolder @

  MEDIA_TYPES.add Models.BaseContent
  MEDIA_TYPES.add Models.BaseBook
  MEDIA_TYPES.add Models.Folder


  # Start listening to URL changes
  new ContentRouter()

  # Because of cyclic dependencies we tack on all of the
  # controller methods onto the exported object instead of
  # just returning the controller object
  jQuery.extend(exports, mainController)
