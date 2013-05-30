define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'aloha'
  'hbs!templates/workspace/menu/toolbar-aloha'
], ($, _, Backbone, Marionette, Aloha, toolbarTemplate) ->

  return new (Marionette.ItemView.extend
    template: toolbarTemplate
    tagName: 'span'

    onRender: ->
      # Wait until Aloha is started before enabling the toolbar
      @$el.addClass('disabled')
      Aloha.ready => @$el.removeClass('disabled')
  )()
