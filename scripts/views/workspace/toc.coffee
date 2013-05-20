define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/toc-branch'
  'hbs!templates/workspace/toc'
], ($, _, Backbone, Marionette, content, TocBranchView, tocTemplate) ->

  return Marionette.CompositeView.extend
    template: tocTemplate
    collection: content
    itemView: TocBranchView
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

    events:
      'click .editor-content-title': 'changeTitle'
      #'click .editor-go-workspace': 'goWorkspace'

    changeTitle: ->
      title = prompt 'Enter a new Title', @model.get('title')
      @model.set 'title', title if title

    #goWorkspace: -> Controller.workspace()
