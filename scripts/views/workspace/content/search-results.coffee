define [
  'marionette'
  'cs!views/workspace/content/search-results-item'
  'cs!views/workspace/menu/toolbar-search'
  'hbs!templates/workspace/content/search-results'
], (Marionette, SearchResultsItemView, searchView, searchResultsTemplate) ->


  # Delay Sorting.
  # When a title is changed multiple `change` events are fired and
  # if the collection is large then calling `allContent.sort()` takes a long time.
  SORT_TIMEOUT = 250 # milliseconds

  # Sorts `allContent` by lastModified, mediaType, and then by title.
  # This is attached to `allContent` when the view is initialized.
  #
  # Reasons for including here instead of on `allContent` directly:
  #
  # - Other implementations of `allContent` would need to copy-pasta this
  # - Other comparators (sort by Title) will probably be added soon
  # - This is the only code that relies on `allContent` being sorted
  #
  # See `Backbone.Collection.comparator`
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

      # Attach the comparator to `allContent`.
      # This guarantees new models are added in sorted order
      # It does **not** guarantee they will remain in sorted order as they change.
      #
      # This is done by listening on `change` events in `allContent` below
      @collection.comparator = SORT_COMPARATOR
      @collection.sort()

      # Start a delayed sort on change:
      #
      # - In a large workspace sort takes a while and the page becomes unresponsive.
      # - Many change events are fired when a single title changes
      @listenTo @collection, 'change', () =>
        if not @sorting
          @sorting = setTimeout ( () =>
            @collection.sort()
            @sorting = false
            ), SORT_TIMEOUT

      # When a sort happens, instead of re-rendering all the children,
      # just reorder the DOM.
      #
      # When a sort event is fired it is guaranteed no other models were
      # added or removed.
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
