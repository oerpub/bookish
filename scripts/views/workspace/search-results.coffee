define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/search-results-item'
  'hbs!templates/workspace/search-results'
], ($, _, Backbone, Marionette, SearchResultsItemView, searchResultsTemplate) ->

  return Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView
