define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/sidebar/toc-branch'
  'hbs!templates/workspace/sidebar/toc'
], ($, _, Backbone, Marionette, content, TocBranchView, tocTemplate) ->

  return Marionette.CompositeView.extend
    template: tocTemplate
    itemView: TocBranchView
    itemViewContainer: 'ol'

    initialize: (options) ->
      @collection = options?.collection or content
      @listenTo(@collection, 'change change:contents', @render)

    # Override Marionette's showCollection()
    showCollection: () ->
      if @collection.branches
        data = @collection.branches()
      else
        data = @collection.models

      _.each data, (item, index) =>
        @addItemView(item, TocBranchView, index)

    events:
      'click .editor-content-title': 'changeTitle'

    changeTitle: ->
      title = prompt('Enter a new Title', @model.get('title'))
      if title then @model.set('title', title)
