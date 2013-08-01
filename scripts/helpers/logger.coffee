# This file takes every `Backbone.Event` and POSTs it to the URL `/logging`
define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  LOGGING_URL = '/logging'

  isEnabled = true

  Backbone.Events.trigger = _.wrap Backbone.Events.trigger, (originalTrigger) ->
    args = _.toArray(arguments).slice(1)

    if isEnabled
      if _.isArray(args)
        log = []
        _.each args, (arg, index, list) ->
          if typeof arg is 'string' or typeof arg is 'number'
            log.push(arg)
          else if _.isArray(arg)
            log.push(JSON.stringify(arg))
          else if typeof arg is 'object'
            if arg.__proto__.constructor and arg.__proto__.constructor.name
              log.push('object: ' + arg.__proto__.constructor.name)

        $.post(LOGGING_URL, JSON.stringify(log))

    originalTrigger.apply(@, args)

  class Logger
    start: () -> isEnabled = true
    stop: () -> isEnabled = false

  return new Logger()
