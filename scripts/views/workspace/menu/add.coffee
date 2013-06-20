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

  AddItemView = Marionette.ItemView.extend
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

      # Begin editing an item as soon as it is added.
      # Some content (like Books and Folders) do not have an `editAction`
      #model.editAction?()

  return new (Marionette.CompositeView.extend
    collection: mediaTypes
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
  )()
