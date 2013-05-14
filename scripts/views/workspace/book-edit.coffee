# Use this to generate HTML with extra divs for Drag-and-Drop zones.
#
# To update the Book model when a `drop` occurs we convert the new DOM into
# a JSON tree and set it on the model.
#
# **FIXME:** Instead of a JSON tree this Model should be implemented using a Tree-Like Collection that has a `.toJSON()` and methods like `.insertBefore()`
define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/book-edit-node'
  'hbs!templates/workspace/book-edit'
], ($, _, Backbone, Marionette, BookEditNodeView, bookEditTemplate) ->

  return Marionette.CompositeView.extend
    template: bookEditTemplate
    itemView: BookEditNodeView
    itemViewContainer: '> nav > ol'

    events:
      'click .editor-content-title': 'changeTitle'
      'click .editor-go-workspace': 'goWorkspace'

    changeTitle: ->
      title = prompt 'Enter a new Title', @model.get('title')
      @model.set 'title', title if title

    goWorkspace: -> Controller.workspace()

    initialize: ->
      #@collection = @model.children()
      #@listenTo @model, 'change:title', => @render()

    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)
