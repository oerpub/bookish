define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  Backbone.Events.trigger = _.wrap Backbone.Events.trigger, (originalTrigger) ->
    args = _.toArray(arguments).slice(1)

    log = {'msg': _.flatten(['trigger', args, console])}
    $.post('/logging', log)

    originalTrigger.apply(@, args)
