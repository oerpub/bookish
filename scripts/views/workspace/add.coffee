define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/media-types'
  'cs!views/workspace/add-item'
  'hbs!templates/workspace/add'
], ($, _, Backbone, Marionette, mediaTypes, AddItemView, addTemplate) ->

  return Marionette.CompositeView.extend
    collection: mediaTypes
    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'
