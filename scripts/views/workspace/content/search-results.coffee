define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/search-results-item'
  'cs!views/workspace/menu/toolbar-search'
  'hbs!templates/workspace/content/search-results'
], ($, _, Backbone, Marionette, SearchResultsItemView, searchView, searchResultsTemplate) ->

  return Marionette.CompositeView.extend
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView

    initialize: () ->
      Marionette.CompositeView::initialize.apply(@, arguments)
      @contents = @collection # Keep a reference to the original collection

      @listenTo(searchView, 'search', @filter)

    filter: (query) ->
      if not query
        @collection = @contents
      else
        # Find all content with a title that matches the search
        filtered = _.filter(@contents.models, (model) ->
          title = model.get('title') or ''
          return title.toLowerCase().search(query.toLowerCase()) >= 0
        )
        @collection = new Backbone.Collection(filtered);

      @render()
