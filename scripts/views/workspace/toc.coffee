define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'hbs!templates/workspace/toc'
  'hbs!templates/workspace/toc-branch'
], ($, _, Backbone, Marionette, content, tocTemplate, tocBranchTemplate) ->

  Branch = Marionette.CompositeView.extend
    template: tocBranchTemplate
    tagName: "li"
    itemViewContainer: '> ol'

    initialize: () ->
      @collection = @model.get('contents')

  return Marionette.CompositeView.extend
    template: tocTemplate
    collection: content
    itemView: Branch
    itemViewContainer: 'ol'

    # It would be nice if Marionette exposed a function to filter a collection
    # Instead, we override showCollection()
    showCollection: () ->
      data = content.branches()
      _.each(data, (item, index) =>
        ItemView = @getItemView(item)
        @addItemView(item, ItemView, index)
      )

    # We also need to override addItemView()
    addItemView: (item, ItemView, index) ->
      if item.branch
        Marionette.CompositeView::addItemView.call(@, item, ItemView, index)
