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
      @on 'change', (model, options) => @_markDirty() if not options.parse and @hasChanged()
      @on 'sync',   (model, options) => @_isDirty = false
    isDirty: () ->
      return @isNew() or @_isDirty

    _markDirty: () ->
      @_isDirty = true
      @trigger 'dirty'
