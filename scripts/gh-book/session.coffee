define ['backbone', 'github'], (Backbone, Github) ->

  class GithubSession extends Backbone.Model
    initialize: () ->
      @on 'change', () =>
        # See if this user can collaborate
        @getRepo().canCollaborate().done (canCollaborate) =>
          @set 'canCollaborate', canCollaborate

    getClient: () ->
      config =
        auth: (if @get('token') then 'oauth' else 'basic')
        token:    @get('token')
        username: @get('id')
        password: @get('password')

      return new Github(config)

    getRepo: () ->
      @getClient().getRepo(@get('repoUser'), @get('repoName'))

    getBranch: () ->
      if @get 'branch'
        @getRepo().getBranch(@get 'branch')
      else
        @getRepo().getDefaultBranch()

  return new GithubSession()
