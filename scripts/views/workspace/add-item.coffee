define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/content'
  'hbs!templates/workspace/add-item'
], ($, _, Backbone, Marionette, content, addItemTemplate) ->

  return Marionette.ItemView.extend
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
