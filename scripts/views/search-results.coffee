define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/search-results-item'
  'hbs!templates/search-results'
], ($, _, Backbone, Marionette, SearchResultsItemView, searchResultsTemplate) ->

  return Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView
