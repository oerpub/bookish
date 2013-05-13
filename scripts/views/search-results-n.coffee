define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/search-results'
], ($, _, Backbone, Marionette, searchResultsTemplate) ->

  return new (Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: exports.SearchResultsItemView
  )()
