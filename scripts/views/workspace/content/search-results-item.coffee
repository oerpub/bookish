define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'moment'
  'cs!collections/media-types'
  'cs!helpers/enable-dnd'
  'hbs!templates/workspace/content/search-results-item'
], ($, _, Backbone, Marionette, Moment, mediaTypes, enableContentDragging, searchResultsItemTemplate) ->

  # Search Result View (workspace)
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
        data.id = @model.id or @model.cid
        data.loading = @model.loading
        return searchResultsItemTemplate(data)

      @listenTo(@model, 'change sync', @render)
      @listenTo(@, 'render show', @updateTimer)

    onRender: () ->
      # Add DnD options to content
      enableContentDragging(@model, @$el.children('*[data-media-type]'))

    # Updates the relative time for a set of elements periodically
    updateTimer: () ->
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
        if document.contains($el.get(0))
          # Generate a relative time and set it as the text of the `time` element
          utc = $el.attr('datetime')
          if utc
            utcTime = Moment.utc(utc)

            # Set the human-readable text for the time
            $el.text(utcTime.fromNow()) # Passing `true` would drop the suffix

            @timerStarted = true
            setTimeout((() -> updateTime($el)), nextUpdate(utcTime))

      if not @timerStarted
        updateTime(@$el.find('time'))
