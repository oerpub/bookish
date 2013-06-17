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

    # It would be nice if Marionette exposed a function to filter a collection
    # Instead, we override showCollection()
    showCollection: () ->
      if @collection.branches
        data = @collection.branches()
      else
        data = @collection.models

      _.each data, (item, index) =>
        @addItemView(item, TocBranchView, index)

    events:
      'click .editor-content-title': 'changeTitle'
      #'click .editor-go-workspace': 'goWorkspace'

    changeTitle: ->
      title = prompt('Enter a new Title', @model.get('title'))
      @model.set('title', title) if title

    #goWorkspace: -> Controller.workspace()
