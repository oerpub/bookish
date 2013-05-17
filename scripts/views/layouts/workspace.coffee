define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/book-edit'
  'cs!views/workspace/search-results'
  'cs!views/layouts/workspace/menu'
  'hbs!templates/layouts/workspace'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, BookEditView, SearchResultsView, menuView, workspaceTemplate) ->

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
      @menu.show(menuView)
      #@sidebar.show(new BookEditView({model: workspaceTree}))
      @sidebar.show(sidebarView)
  )()
