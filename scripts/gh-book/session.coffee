define ['backbone', 'github'], (Backbone, Github) ->

  class GithubSession extends Backbone.Model
    initialize: () ->
      @_reloadClient()

      @on 'change', () =>
        @_reloadClient()

        # See if this user can collaborate
        @getRepo().canCollaborate().done (canCollaborate) =>
          @set 'canCollaborate', canCollaborate

    _reloadClient: () ->
      config =
        auth: (if @get('token') then 'oauth' else 'basic')
        token:    @get('token')
        username: @get('id')
        password: @get('password')
      @_client = new Github(config)

    getClient: () ->
      return @_client or throw 'BUG: Client was not loaded yet'

    getRepo: () ->
      @getClient().getRepo(@get('repoUser'), @get('repoName'))

    getBranch: () ->
      if @get 'branch'
        @getRepo().getBranch(@get 'branch')
      else
        @getRepo().getDefaultBranch()

  return new GithubSession()
