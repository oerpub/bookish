define [
  'jquery'
  'underscore'
  'aloha'
  'hbs!templates/workspace/dnd-handle'
], ($, _, Aloha, dndHandleTemplate) ->

  # Drag and Drop Behavior
  # -------
  #
  # Several views allow content to be dragged around.
  # Each item that is draggable **must** contain 3 DOM attributes:
  #
  # - `data-content-id`:    The unique id of the piece of content (it can be a path)
  # - `data-media-type`:    The mime-type of the content being dragged
  # - `data-content-title`: A  human-readable title for the content
  #
  # In addition it may contain the following attributes:
  #
  # - `data-drag-operation="copy"`: Specifies the CSS to add a "+" when dragging
  #                                 hinting that the element will not be removed.
  #                                 (For example, content in a search result)
  #
  # Additionally, each draggable element should not contain any text children
  # so CSS can hide children and properly style the cloned element that is being dragged.
  enableContentDragging = (model, $content) ->
    $content.data('editor-model', model)
    $content.draggable
      addClasses: false
      revert: 'invalid'
      # Ensure the handle is on top (zindex) and not bound to be constrained inside a div visually
      appendTo: 'body'
      # Place the little handle right next to the mouse
      cursorAt:
        top: 0
        left: 0
      helper: (evt) ->
        title = model.get('title') or ''
        shortTitle = title.substring(0, 20)
        if title.length > 20 then shortTitle += '...'

        # If the content is a pointer to a piece of content (`BookTocNode`)
        # then use the actual content's mediaType
        mediaType = model.mediaType

        # Generate the handle div using a template
        handle = dndHandleTemplate
          id: model.id
          mediaType: mediaType
          title: title
          shortTitle: shortTitle

        return $(handle)

  # Since we use jqueryui's draggable which is loaded when Aloha loads
  # delay until Aloha is finished loading
  return (model, $content) ->
    Aloha.ready =>
      enableContentDragging(model, $content)

      # Figure out which mediaTypes can be dropped onto each element
      $.each $content, (key, el) ->
        $el = $(el)

        #ModelType = mediaTypes.get(@model.mediaType)
        validSelectors = _.map(model.accepts?(), (mediaType) -> "*[data-media-type=\"#{mediaType}\"]")
        validSelectors = validSelectors.join(',')

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
              #if drop.accepts().indexOf(model.mediaType) < 0
              #  model = model.dereference()
              #throw 'INVALID_DROP_MEDIA_TYPE' if drop.accepts().indexOf(model.mediaType) < 0

              # Delay the call so $.droppable has time to clean up before the DOM changes
              delay = => drop.add(model)
              setTimeout(delay, 10)
