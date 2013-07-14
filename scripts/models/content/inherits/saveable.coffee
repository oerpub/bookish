define ['backbone'], (Backbone) ->

  return class Saveable extends Backbone.Model
    initialize: () ->
      @on 'change', (model, options) => @_isDirty = true  if not options.parse and @hasChanged()
      @on 'sync',   (model, options) => @_isDirty = false
    isDirty: () ->
      return @isNew() or @_isDirty
