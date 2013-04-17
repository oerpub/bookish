define ['github', 'backbone'], (Github, Backbone) ->

  # Singleton variables representing the Github user and current repo
  github = null
  repo = null

  # For the UI, provide a backbone "interface" to the auth piece
  AuthModel = Backbone.Model.extend
    defaults:
      id: '' # Set `username` to `id` so Save view knows when to alert the user to log in
      password: ''
      auth: 'basic'

      repoUser: 'philschatz'
      repoName: 'github-book'

      branch: 'sample-book'
      # **Remember:** `rootPath` always needs a trailing slash!
      rootPath: ''

    # Updates the singleton variables `github` and `repo`
    _update: ->
      credentials =
        username: @get 'id'
        password: @get 'password'
        token:    @get 'token'
        auth:     @get 'auth'
      github = new Github(credentials)
      repo = null

      json = @toJSON()
      if json.repoUser and json.repoName
        repo = github.getRepo json.repoUser, json.repoName

      # Listen to the RateLimit changes and update the model
      # @set {rateRemaining: -1, rateLimit: -1}
      github.onRateLimitChanged (remaining, limit) =>
        @set {rateRemaining: remaining, rateLimit: limit}


    initialize: ->
      @_update()

      @on 'change:id',       @_update
      @on 'change:password', @_update
      @on 'change:token',    @_update
      @on 'change:auth',     @_update
      @on 'change:repoUser', @_update
      @on 'change:repoName', @_update

    authenticate: (credentials) -> @set credentials
    setRepo: (repoUser, repoName) -> @set
      repoUser: repoUser
      repoName: repoName

    getRepo: -> repo
    getUser: -> github?.getUser()
    signOut: ->
      github = null
      repo = null
      @set {
        id: ''
        password: ''
      }

    # When saving do not run `Backbone.sync`.
    sync: (method, model, options) ->
      @_update()
      # Fire the success callback if it exists
      options?.success?()

  return new AuthModel()
