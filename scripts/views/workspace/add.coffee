define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/add-item'
  'hbs!templates/workspace/add'
], ($, _, Backbone, Marionette, AddItemView, addTemplate) ->

  return Marionette.CompositeView.extend
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
