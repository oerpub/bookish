define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/content/search-results-item'
  'hbs!templates/workspace/content/search-results'
], ($, _, Backbone, Marionette, content, SearchResultsItemView, searchResultsTemplate) ->

  return new (Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView
    collection: content
  )()
