define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/content/search-results'
  'cs!views/layouts/workspace/menu'
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace'
], ($, _, Backbone, Marionette, content, SearchResultsView, menuLayout, sidebarLayout, workspaceTemplate) ->

  class Workspace extends Marionette.Layout
    template: workspaceTemplate

    regions:
      content: '#content'
      menu: '#menu'
      sidebar: '#sidebar'

    onRender: () ->
      @showViews()

    showViews: (options) ->
      @model = options?.model

      # Make sure the menu is loaded
      if not @menu.currentView
        @menu.show(menuLayout)

      # Load the content view
      if @model?.contentView?
        @model.contentView((view) => if view then @content.show(view))
      else @content.show(new SearchResultsView({collection: content}))

      # Load the menu's toolbar
      if @model?.toolbarView?
        @model.toolbarView((view) => if view then @menu.currentView.showToolbar(view))
      else @menu.currentView.showToolbar()

      # Load the sidebar
      if @model?.sidebarView?
        @model.sidebarView((view) => if view then @sidebar.show(view))
      else @sidebar.show(sidebarLayout)
