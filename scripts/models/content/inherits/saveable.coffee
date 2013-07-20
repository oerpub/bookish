# A Saveable model will mark itself as "dirty" when its contents changes since the last Save/fetch.
#
# When a fetch occurs a special boolean option named `parse` is passed in to `Model.set`
# which we check for so we don't set the dirty flag.
#
# When the `dirty` flag is set, an event is fired named `dirty`.
#
# **Note:** If this was an attribute on the model views could just listen to `change` or `change:dirty`
#   but we would need to strip it out when saving.
#
# On containers:
# Containers are Models that contain a collection. They should call `_markDirty`
#   when items are added/removed/reset.
define ['backbone'], (Backbone) ->

  return class Saveable extends Backbone.Model
    initialize: () ->
      @on 'sync',   (model, options) => @_isDirty = false

      # FIXME: To reduce the number of change events (view render), either:
      # - include the `dateLastModified` in the set of changes by wrapping `Backbone.set`
      # - update view code so it does not have to re-render; it would change the rendered DOM directly
      @on 'change', (model, options) => @_markDirty(options)

      if @isNew()
        @loaded = true
        @_markDirty({}, true)


    isDirty: () ->
      return @isNew() or @_isDirty

    _markDirty: (options, force=false) ->
      throw 'BUG: markDirty takes 1 argument' if not options
      # `options.parse` is set during `Backbone.fetch` and sometimes `change`
      # is triggered (by our code I believe) without anything being in the
      # change set.
      #
      # In both cases, do not set the lastModified time.
      if (not options.parse and @hasChanged()) or force
        # Mark this model as dirty and trigger an event
        @_isDirty = true
        @trigger 'dirty'

        # Prevent the next set from triggering this event handler indefinitely.
        # This hack can be removed if FIXME #1 is used.
        options.parse = true

        @set 'dateLastModifiedUTC', (new Date()).toJSON(), options

    # Everything that is Saveable needs a `mediaType` so the webserver can distinguish between
    # different types of content (Book, Module, etc)
    toJSON: (options) ->
      json = super(options)
      json.mediaType = @mediaType
      return json
