define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  return new (Backbone.Model.extend
    defaults:
      accessToken: null
      userId: null
    
    initialize: () ->
      @load()

    authenticated: () ->
      return true

    save: (authHash) ->
      console.log 'save session'

    load: () ->
      console.log 'load session'
  )()
