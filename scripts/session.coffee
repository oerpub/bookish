define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  _authenticated = false

  return new (class Session extends Backbone.Model
    url: '/me'

    initialize: () ->
      @load()

    load: () ->
      @fetch
        success: (model, response, options) =>
          if response.user_id
            # Logged in

            @set('user', response)

            _authenticated = true;
            @trigger('login')

        error: (model, response, options) ->
          console.log 'Failed to load session.'

    login: () ->
      this.load()

    logout: () ->
      this.reset()
      this.clear()
      this.trigger('logout')

    reset: () ->
      _authenticated = false
      @set('user', null)

    authenticated: () ->
      return _authenticated

    user: () ->
      return @get('user')
  )()
