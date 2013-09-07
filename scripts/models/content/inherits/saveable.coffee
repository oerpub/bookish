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

  INTERNAL_ATTRIBUTES = [
    '_original'
  ]

  return class Saveable extends Backbone.Model
    initialize: () ->
      # FIXME: To reduce the number of change events (view render), either:
      # - include the `dateLastModified` in the set of changes by wrapping `Backbone.set`
      # - update view code so it does not have to re-render; it would change the rendered DOM directly
      @on 'change', (model, options) =>
        # Do not mark dirty if only "_*" attributes are changed
        if _.isEmpty _.omit model.changedAttributes(), INTERNAL_ATTRIBUTES
          # Pass because only internal attributes were changed
        else if options.parse
          # Pass because this model is being set by `parse()`
        else
          @_markDirty(options)

      # When fetching, save the original content **before**
      # it has gone through `parse()` and `serialize()`
      @on 'sync', (model, resp, options) => @set('_original', resp.content)

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

    onSaved: () ->
      # If the content was just added, squirrel away the content into _ooriginal for visual Diffing later
      @set('_original', @serialize?())
      @_isDirty = false
      @_isNew = false # Set in loadable
