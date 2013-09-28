define [
  'marionette'
  'aloha'
  'hbs!templates/workspace/menu/toolbar-aloha'
], (Marionette, Aloha, toolbarTemplate) ->

  return new class ToolbarAlohaView extends Marionette.ItemView
    template: toolbarTemplate
    tagName: 'span'

    onRender: ->
      @$el.find('.btn.currentHeading').on 'click', (e) -> e.preventDefault()
      # Wait until Aloha is started before enabling the toolbar
      @$el.addClass('disabled')
      Aloha.ready => @$el.removeClass('disabled')
