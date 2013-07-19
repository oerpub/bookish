define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'moment'
  'cs!controllers/routing'
  'cs!collections/media-types'
  'cs!helpers/enable-dnd'
  'hbs!templates/workspace/content/search-results-item'
], ($, _, Backbone, Marionette, Moment, controller, mediaTypes, EnableDnD, searchResultsItemTemplate) ->

  # Search Result View (workspace)
  # -------
  #
  # A list of search results (stubs of models only containing an icon, url, title)
  # need a generic view for an item.
  #
  # Since we don't really distinguish between a search result view and a workspace/collection/etc
  # just consider them the same.
  return class SearchResultsItem extends Marionette.ItemView
    tagName: 'tr'

    template: searchResultsItemTemplate

    events:
      'click .go-edit': 'goEdit'

    goEdit: () -> controller.goEdit(@model)

    templateHelpers: () ->
      return {
        id: @model.id or @model.cid
        mediaType: @model.mediaType
        isLoaded: @isLoaded
        isDirty: @model.isDirty()
      }

    initialize: () ->
      @listenTo(@model, 'dirty change sync', @render)
      @listenTo(@, 'render show', @startUpdateTimer)

    onRender: () ->
      # Add DnD options to content
      EnableDnD.enableContentDnD(@model, @$el.children('*[data-media-type]'))

    # Stop updating the timer when the view is detached
    onClose: () -> @keepUpdating = false

    # Updates the relative time for a set of elements periodically
    startUpdateTimer: () ->
      nextUpdate = (utcTime) ->
        now = Moment()
        diff = now.diff(utcTime) / 1000 # Put it in Seconds instead of milliseconds
        # If the update was in the future then change it to be `a few seconds ago`
        if diff < 0 then utcTime = now

        secs = 10
        if diff < 60 then secs = 5 # update in 5 seconds
        else if diff < 60 * 60 then secs = 30 # update in 30 seconds
        else secs = 60 * 2  # update in 2 minutes

        return secs * 1000

      updateTime = ($el) =>
        if @keepUpdating
          # Generate a relative time and set it as the text of the `time` element
          utc = $el.attr('datetime')
          if utc
            utcTime = Moment.utc(utc)

            # Set the human-readable text for the time
            $el.text(utcTime.fromNow()) # Passing `true` would drop the suffix

            setTimeout((() -> updateTime($el)), nextUpdate(utcTime))

      @keepUpdating = true
      updateTime(@$el.find('time'))
