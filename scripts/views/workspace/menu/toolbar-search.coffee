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

    events:
      'keyup .search-query': 'search'

    onRender: () ->
      # Make sure we have delegated events
      @delegateEvents()

    search: (e) ->
      @trigger('search', $(e.currentTarget).val())
  )()
