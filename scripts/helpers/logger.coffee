define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  isEnabled = true

  Backbone.Events.trigger = _.wrap Backbone.Events.trigger, (originalTrigger) ->
    args = _.toArray(arguments).slice(1)

    if isEnabled
      log = "trigger: #{ args }"
      $.post('/logging', log)

    originalTrigger.apply(@, args)

  class Logger
    start: () -> isEnabled = true
    stop: () -> isEnabled = false

  return new Logger()
