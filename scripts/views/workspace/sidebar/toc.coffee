define [
  'underscore'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/sidebar/toc-branch'
  'hbs!templates/workspace/sidebar/toc'
], (_, Marionette, allContent, TocBranchView, tocTemplate) ->

  return class TocView extends Marionette.CompositeView
    template: tocTemplate
    itemView: TocBranchView
    itemViewContainer: 'ol'

    initialize: (options) ->
      if options?.collection
        @collection = options.collection
        @showNodes = true
      else
        @collection = allContent

    templateHelpers: () ->
      return {mediaType: @model?.mediaType}

    # Used by TocBranchView to know which collection to ask for an overridden title
    itemViewOptions: () ->
      return {container: @collection}

    # Override Marionette's showCollection()
    showCollection: () ->
      if @collection.branches
        data = @collection.branches()
      else
        data = @collection.models

      _.each data, (item, index) =>
        @addItemView(item, TocBranchView, index)

    # We also need to override addItemView()
    addItemView: (item, ItemView, index) ->
      if item.branch or @showNodes
        super(item, ItemView, index)

    # Override internal Marionette method.
    # This method adds a child list item at a given index.
    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)

    events:
      'click .editor-content-title': 'changeTitle'

    changeTitle: () ->
      title = prompt('Enter a new Title', @model.get('title'))
      if title then @model.set('title', title)
      @render()
