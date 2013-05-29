define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/menu/toolbar-aloha'
], ($, _, Backbone, Marionette, toolbarTemplate) ->

  return new (Marionette.ItemView.extend
    template: toolbarTemplate
    tagName: 'span'
  )()
