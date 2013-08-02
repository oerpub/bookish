define ['underscore', 'backbone', 'github'], (_, Backbone, Github) ->

  class GithubSession extends Backbone.Model
    initialize: () ->
      @_reloadClient()

      @on 'change', () =>
        # If any authentication info has changed then reload the client
        if not _.isEmpty _.pick @.changed, ['token', 'id', 'password']
          @_reloadClient()

        # If any of the repo settings change then check if the user can still collaborate
        else if not _.isEmpty _.pick @.changed, ['repoUser', 'repoName']
          @checkCanCollaborate()

    _reloadClient: () ->
      config =
        auth: (if @get('token') then 'oauth' else 'basic')
        token:    @get('token')
        username: @get('id')
        password: @get('password')
      @_client = new Github(config)

      # Check if the user can collaborate on the current repo (if one is set)
      @checkCanCollaborate()

    checkCanCollaborate: () ->
      # See if this user can collaborate
      return @getRepo()?.canCollaborate().done (canCollaborate) =>
        @set 'canCollaborate', canCollaborate

    getClient: () ->
      return @_client or throw 'BUG: Client was not loaded yet'

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
