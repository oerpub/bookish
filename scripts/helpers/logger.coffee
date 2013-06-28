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
      log = "trigger: #{ args }"
      $.post(LOGGING_URL, log)

    originalTrigger.apply(@, args)

  class Logger
    start: () -> isEnabled = true
    stop: () -> isEnabled = false

  return new Logger()
