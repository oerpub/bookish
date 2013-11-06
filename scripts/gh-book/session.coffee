define ['underscore', 'backbone', 'github'], (_, Backbone, Github) ->

  ROOT_URL = undefined # 'http://localhost:3000'

  class GithubSession extends Backbone.Model
    initialize: () ->
      # The session will be (re-)initialised when the app sets our login
      # details, or if it is changed.
      @on 'change', (s, options) =>
        # Internal signal not to reload. Used by authenticate below.
        return if options and options.noreload

        # If any authentication info has changed then reload the client
        if not _.isEmpty _.pick @.changed, ['token', 'id', 'password']
          @_reloadClient()

        # If any of the repo settings change then check if the user can still
        # collaborate
        else if not _.isEmpty _.pick @.changed, ['repoUser', 'repoName']
          @checkCanCollaborate()

    authenticate: (config) ->
      # This works pretty similar to _reloadClient, except that it tests the
      # login details first and only replaces the client if it succeeds. The
      # promise is returned so more actions can be hung off it.
      client = new Github
        auth: (if config.token then 'oauth' else 'basic')
        token:    config.token
        username: config.id
        password: config.password
        rootURL: ROOT_URL

      promise = client.getLogin()
      promise.done () =>
        @set config, {noreload: true}
        @_client = client
        @checkCanCollaborate()
      return promise

    _reloadClient: () ->
      config =
        auth: (if @get('token') then 'oauth' else 'basic')
        token:    @get('token')
        username: @get('id')
        password: @get('password')
        rootURL: ROOT_URL
      @_client = new Github(config)

      # Check if the user can collaborate on the current repo (if one is set)
      @checkCanCollaborate()

    checkCanCollaborate: () ->
      # Shortcut to false if no token or password is provided
      if not (@get('token') or @get('password'))
        @set('canCollaborate', false)

      else
        # See if this user can collaborate
        @getRepo()?.canCollaborate().done (canCollaborate) =>
          @set('canCollaborate', canCollaborate)

    getClient: () ->
      if not @_client
        console?.warn('Using anonymous access for the GithUb API')
        @_client = new Github({})
        @set('canCollaborate', false)
      return @_client 

    getRepo: () ->
      repoUser = @get('repoUser')
      repoName = @get('repoName')
      @getClient().getRepo(repoUser, repoName) if repoUser and repoName

    getBranch: () ->
      if @get 'branch'
        @getRepo()?.getBranch(@get 'branch')
      else
        @getRepo()?.getDefaultBranch()

  return new GithubSession()
