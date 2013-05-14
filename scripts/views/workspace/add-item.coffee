define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/add-item'
], ($, _, Backbone, Marionette, addItemTemplate) ->

  return Marionette.ItemView.extend
    template: addItemTemplate
    tagName: 'li'
    events:
      'click button': 'addItem'

    addItem: ->
      ContentType = @model.get('modelType')
      content = new ContentType()
      #Models.WORKSPACE.add content
      # Begin editing an item as soon as it is added.
      # Some content (like Books and Folders) do not have an `editAction`
      #content.editAction?()
