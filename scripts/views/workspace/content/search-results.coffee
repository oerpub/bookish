define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/search-results-item'
  'hbs!templates/workspace/search-results'
], ($, _, Backbone, Marionette, content, SearchResultsItemView, searchResultsTemplate) ->

  return Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView
    collection: content
