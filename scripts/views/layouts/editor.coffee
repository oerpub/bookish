define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/search-results'
  'cs!views/layouts/workspace/menu'
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/main'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, SearchResultsView, menuLayout, sidebarLayout, mainTemplate) ->

  return Marionette.Layout.extend
    template: mainTemplate({layout: 'editor'})

    regions:
      content: '#content'
      menu: '#menu'
      sidebar: '#sidebar'

    onRender: () ->
      @content.show(new SearchResultsView())
      @menu.show(menuLayout)
      @sidebar.show(sidebarLayout)
