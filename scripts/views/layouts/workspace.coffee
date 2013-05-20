define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/search-results'
  'cs!views/layouts/workspace/menu'
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, SearchResultsView, menuLayout, sidebarLayout, workspaceTemplate) ->

  return new (Marionette.Layout.extend
    template: workspaceTemplate

    regions:
      content: '#content'
      menu: '#menu'
      sidebar: '#sidebar'

    render: () ->
      Marionette.Layout::render.apply(@, arguments)
      @load()

    load: () ->
      @content.show(new SearchResultsView())
      @menu.show(menuLayout)
      #@sidebar.show(new BookEditView({model: workspaceTree}))
      @sidebar.show(sidebarLayout)
  )()
