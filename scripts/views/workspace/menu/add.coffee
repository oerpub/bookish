define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'cs!collections/media-types'
  'hbs!templates/workspace/menu/add'
  'hbs!templates/workspace/menu/add-item'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, content, mediaTypes, addTemplate, addItemTemplate) ->

  class AddItemView extends Marionette.ItemView
    tagName: 'li'

    initialize: () ->
      @template = (data) =>
        data.id = @model.id
        return addItemTemplate(data)

    events:
      'click .add-content-item': 'addItem'

    addItem: (e) ->
      e.preventDefault()

      model = new (@model.get('modelType'))()
      model.loaded = true
      content.add(model)

      # Begin editing certain media as soon as they are added.
      model.addAction?()

  return new class AddView extends Marionette.CompositeView
    collection: mediaTypes
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
