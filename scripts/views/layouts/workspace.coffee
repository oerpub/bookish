define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/search-results'
  'cs!views/layouts/workspace/menu'
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace'
], ($, _, Backbone, Marionette, SearchResultsView, menuLayout, sidebarLayout, workspaceTemplate) ->

  return Marionette.Layout.extend
    template: workspaceTemplate

    regions:
      content: '#content'
      menu: '#menu'
      sidebar: '#sidebar'

    onRender: () ->
      @load(@model)

    load: (options) ->
      @model = options?.model

      if typeof @model is 'object'
        # load editor view
        @model.contentView?((view) => if view then @content.show(view))
        @model.toolbarView?((view) => if view then @menu.currentView.toolbar.show(view))
        @model.sidebarView?((view) => if view then @sidebar.show(view))
      else
        # load default view
        @content.show(new SearchResultsView())
        @menu.show(menuLayout)
        @sidebar.show(sidebarLayout)
