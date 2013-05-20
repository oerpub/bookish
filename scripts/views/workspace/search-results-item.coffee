define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'aloha'
  'hbs!templates/workspace/search-results-item'
], ($, _, Backbone, Marionette, Aloha, searchResultsItemTemplate) ->

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
    template: searchResultsItemTemplate
    
    initialize: ->
      @listenTo @model, 'change', => @render()
    onRender: ->
      # Render the modified time in a relative format and update it periodically
      $times = @$el.find('time[datetime]')
      #updateTimes $times

      @$el.on 'click', => Controller.editModel(@model)
      # Add DnD options to content
      $content = @$el.children('*[data-media-type]')

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>

        _EnableContentDragging(@model, $content)

        # Figure out which mediaTypes can be dropped onto each element
        $content.each (i, el) =>
          $el = $(el)

          ModelType = MEDIA_TYPES.get @model.mediaType
          validSelectors = _.map ModelType::accepts(), (mediaType) -> "*[data-media-type=\"#{mediaType}\"]"
          validSelectors = validSelectors.join ','

          if validSelectors
            $el.droppable
              greedy: true
              addClasses: false
              accept: validSelectors
              activeClass: 'editor-drop-zone-active'
              hoverClass: 'editor-drop-zone-hover'
              drop: (evt, ui) =>
                $drag = ui.draggable
                $drop = $(evt.target)

                # Find the model representing the id that was dragged
                model = $drag.data 'editor-model'
                drop = $drop.data 'editor-model'
                # Sanity-check before dropping:
                # Dereference if this is a pointer
                if drop.accepts().indexOf(model.mediaType) < 0
                  model = model.dereference()
                throw 'INVALID_DROP_MEDIA_TYPE' if drop.accepts().indexOf(model.mediaType) < 0

                # Delay the call so $.droppable has time to clean up before the DOM changes
                delay = => drop.addChild model
                setTimeout delay, 10
    