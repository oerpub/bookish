define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  Backbone.Events.trigger = _.wrap Backbone.Events.trigger, (originalTrigger) ->
    args = _.toArray(arguments).slice(1)
    console.log args
    console.log console, _.flatten(['trigger', args])

    originalTrigger.apply(@, args)
