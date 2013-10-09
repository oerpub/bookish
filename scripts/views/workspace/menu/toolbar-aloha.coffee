define [
  'jquery'
  'marionette'
  'aloha'
  'hbs!templates/workspace/menu/toolbar-aloha'
  'hbs!templates/workspace/menu/toolbar-popover'
], ($, Marionette, Aloha, toolbarTemplate, toolbarPopover) ->

  return new class ToolbarAlohaView extends Marionette.ItemView
    template: toolbarTemplate
    tagName: 'span'

    onRender: ->
      # If someone clicks the heading button, don't reload the page
      @$el.find('.btn.currentHeading').on 'click', (e) -> e.preventDefault()

      # This will attach a popover to any button in the toolbar that has a
      # data-content attribute. This essentially defers what buttons
      # have a popover to the toolbar template itself. It allows the design of
      # a UI that can occasionally point to a button and tell the user what it
      # does, that is, it aids in discoverability. This uses the new `flash`
      # feature in the aloha toolbar. Whenever a plugin asks the toolbar to
      # flash a button, we catch that event and show the popover. We only show
      # the popover on the first flash event. Finally, we also glue a handler
      # to the .close element inside that popover, because bootstrap does not
      # handle this natively.

      @$el.find('.action[data-content]')
      .popover(
        placement: 'bottom',
        trigger: 'manual'
        html: true
        template: toolbarPopover({})
        container: '#menu-and-content')
      .on 'shown', (e1) ->
        $(e1.target).data('popover').$tip.find('.close').off('click').on 'click', (e2) ->
          e2.preventDefault()
          $(e1.target).popover('hide')

      @$el.one 'flash-action', (e) -> $(e.target).popover('show')

      # Wait until Aloha is started before enabling the toolbar
      @$el.addClass('disabled')
      Aloha.ready => @$el.removeClass('disabled')
