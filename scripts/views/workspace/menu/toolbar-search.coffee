define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/menu/toolbar-search'
], ($, _, Backbone, Marionette, toolbarTemplate) ->

  return new (Marionette.ItemView.extend
    template: toolbarTemplate
    tagName: 'span'
  )()
