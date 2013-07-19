define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/search-results-item'
  'cs!views/workspace/menu/toolbar-search'
  'hbs!templates/workspace/content/search-results'
], ($, _, Backbone, Marionette, SearchResultsItemView, searchView, searchResultsTemplate) ->

  SORT_TIMEOUT = 250 # milliseconds

  SORT_COMPARATOR = (modelA, modelB) ->
    compareAttribute = (name, desc=false) ->
      valueA = modelA.get(name)
      valueB = modelB.get(name)

      if valueA and valueB
        if valueA < valueB
          ret = -1
        else if valueA > valueB
          ret = 1
        else
          ret = 0

        # Flip if descending order
        ret = 0 - ret if desc

      else if valueA
        ret = -1
      else if valueB
        ret = 1
      else
        ret = 0

      return ret

    return compareAttribute('dateLastModifiedUTC', true) or
           compareAttribute('mediaType') or
           compareAttribute('title') or
           compareAttribute('id')

  return class SearchResultsView extends Marionette.CompositeView
    template: searchResultsTemplate
    itemViewContainer: 'tbody'
    itemView: SearchResultsItemView

    initialize: () ->
      super()
      @contents = @collection # Keep a reference to the original collection

      @listenTo(searchView, 'search', @filter)


      @collection.comparator = SORT_COMPARATOR
      @collection.sort()

      @listenTo @collection, 'change', () =>
        if not @sorting
          @sorting = setTimeout ( () =>
            @collection.sort()
            @sorting = false
            ), SORT_TIMEOUT

      @listenTo @collection, 'sort', () => @reorder()


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

    # Instead of re-rendering each view when sorting, just update the ordering
    # of the rendered elements in the DOM
    reorder: () ->

      @collection.each (childModel, index) =>
        $containerChildren = @$itemViewContainer.children()

        childView = @children.findByModel(childModel)
        $el = childView.$el
        childIndex = $containerChildren.index($el)

        if index != childIndex
          $el.insertBefore($containerChildren.eq(index))
