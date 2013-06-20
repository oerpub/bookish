define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/media-types'
  'cs!helpers/enable-dnd'
  'hbs!templates/workspace/content/search-results-item'
], ($, _, Backbone, Marionette, mediaTypes, enableContentDragging, searchResultsItemTemplate) ->

  # Search Result Views (workspace)
  # -------
  #
  # A list of search results (stubs of models only containing an icon, url, title)
  # need a generic view for an item.
  #
  # Since we don't really distinguish between a search result view and a workspace/collection/etc
  # just consider them the same.
  return Marionette.ItemView.extend
    tagName: 'tr'

    initialize: () ->
      @template = (data) =>
        data.id = @model.id
        return searchResultsItemTemplate(data)

      @listenTo @model, 'change', => @render()

    onRender: () ->
      # Render the modified time in a relative format and update it periodically
      $times = @$el.find('time[datetime]')
      #updateTimes $times

      # Add DnD options to content
      enableContentDragging(@model, @$el.children('*[data-media-type]'))
