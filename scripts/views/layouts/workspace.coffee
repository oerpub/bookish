define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/search-results'
  'hbs!templates/layouts/workspace'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, SearchResultsView, workspaceTemplate) ->

  return new (Marionette.Layout.extend
    template: workspaceTemplate

    regions:
      menu: '#menu'
      sidebar: '#sidebar'
      content: '#content'
    
    load: () ->
      #@menu.show()
      #@sidebar.show()
      @content.show(new SearchResultsView())
  )()
