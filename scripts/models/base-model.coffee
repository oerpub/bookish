define [
  'jquery'
  'underscore'
  'backbone'
  'cs!collections/media-types'
], ($, _, Backbone, mediaTypes) ->

  # Custom Models are mixed in using `BaseContent.initialize`
  return Backbone.Model.extend
    # New content is given an id before it is saved so it can be added to a book.
    # A book can refer to a new piece of content in its Table of Contents
    # (which could be stored in a HTML `<a href="[id]"/>` tag) so it needs some `id`.
    #
    # The Book Model can then listen to `change:id` and update the link when the
    # new content is saved and the id is updated.
    isNew: -> not @id or @id.match(/^_NEW:/)
    initialize: ->
      throw 'BUG: No mediaType set' if not @mediaType
      throw 'BUG: No mediaType not registered' if not mediaTypes.get @mediaType
      @set {id:"_NEW:#{@cid}", _isDirty:true} if not @id

      # If anything but one of the *meta* attributes changes then set the dirty bit.
      #
      # Some meta attributes:
      #
      # * `_isDirty`
      # * `_loading`
      # * `_loaded`
      @on 'change', =>
        attrs = @changedAttributes()
        # Remove all keys starting with `_`.
        # Then set the dirty bit if anything else changed
        for key in _.keys(attrs)
          delete attrs[key] if /^_/.test key

        @set {_isDirty:true} if _.keys(attrs).length

    # Add the `mediaType` to the JSON
    toJSON: ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      return json

    # List of mediaTypes that are allowed to be children of this type.
    # Used by the Drag-and-Drop to decide which types can be dropped and
    # by `AddView` to decide which child mediaTypes can be added.
    accepts: -> []
    # Returns a `Backbone.Collection` of children of this model (`null` if children are not allowed).
    # Used by the TreeView to render the children of this node.
    children: -> null
    # Adds a child assuming it's mediaType is in `.accepts()`
    addChild: (model, at=null) ->
      # Set the `parent` in the options so we can rerender the parent in the view
      # (for lazy redrawing)
      options = {parent: @}
      options.at = at if at >= 0
      # By default unwrap pointers
      model = model.dereference()
      @children().add model, options

    # Some models are pointers to other models (ie `BookTocNode`).
    # Dereference them.
    # By default, return this.
    dereference: -> @

    # `Controller` action to edit this model or `null` if it cannot be edited directly
    editAction: null
