define ['backbone'], (Backbone) ->

  _authenticated = false

  return new class Session extends Backbone.Model
    url: '/me'

    login: () ->
      # Hardcoded user
      @set 'user',
        "middlename": "Harper"
        "lastname": "Lee"
        "user_id": "1d9224a5-6900-40f8-99b8-6333175acbb7"
        "firstname": "Nelle"
        "email": null

      _authenticated = true
      @trigger('login')

    logout: () ->
      @reset()
      @clear()
      @trigger('logout')

    reset: () ->
      _authenticated = false
      @set('user', null)

    authenticated: () ->
      return _authenticated

    user: () ->
      return @get('user')
