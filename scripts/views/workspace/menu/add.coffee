define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'hbs!templates/workspace/menu/add'
  'hbs!templates/workspace/menu/add-item'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, content, addTemplate, addItemTemplate) ->

  class AddItemView extends Marionette.ItemView
    tagName: 'li'

    template: addItemTemplate

    events:
      'click .add-content-item': 'addItem'

    addItem: (e) ->
      e.preventDefault()

      model = new (@model.get('modelType'))()
      model.loaded = true
      content.add(model)

      # Begin editing certain media as soon as they are added.
      model.addAction?()

  return class AddView extends Marionette.CompositeView
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
