define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/menu/toolbar-search'
], ($, _, Backbone, Marionette, toolbarTemplate) ->

  _rendered = false

  return new class ToolbarSearchView extends Marionette.ItemView
    template: toolbarTemplate
    tagName: 'span'

    events:
      'keyup .search-query': 'search'

    onRender: () ->
      # Marionette won't re-delegate events if we close this view
      # and then re-show it, so do it here.
      if _rendered then @delegateEvents()
      _rendered = true

    search: (e) ->
      @trigger('search', $(e.currentTarget).val())
