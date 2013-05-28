define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!collections/media-types'
  'hbs!templates/workspace/menu/add'
  'hbs!templates/workspace/menu/add-item'
], ($, _, Backbone, Marionette, content, mediaTypes, addTemplate, addItemTemplate) ->

  AddItemView = Marionette.ItemView.extend
    template: addItemTemplate
    tagName: 'li'
    events:
      'click button': 'addItem'

    addItem: (e) ->
      e.preventDefault()

      content.add(new (@model.get('modelType'))())

      # Begin editing an item as soon as it is added.
      # Some content (like Books and Folders) do not have an `editAction`
      #content.editAction?()

  return Marionette.CompositeView.extend
    collection: mediaTypes
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
