define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  wrapper = (trigger) ->
    return _.wrap trigger, (originalTrigger) ->
      args = _.toArray(arguments).slice(1)

      log = "trigger: #{ args }"
      $.post('/logging', log)

      originalTrigger.apply(@, args)

  logger = {
    start: () ->
      Backbone.Events.trigger = wrapper(Backbone.Events.trigger)
  };

  logger.start()

  return logger
