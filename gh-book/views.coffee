define [
  'underscore'
  'backbone'
  'marionette'
  'bookish/controller'
  'bookish/models'
  'epub/models'
  'bookish/auth'
  'bookish/views'
  'hbs!gh-book/sign-in-out'
  'hbs!gh-book/fork-book-item'
], (_, Backbone, Marionette, Controller, AtcModels, EpubModels, Auth, Views, SIGN_IN_OUT, FORK_BOOK_ITEM) ->


  # ## Auth View
  # The top-right of each page should have either:
  #
  # 1. a Sign-up/Login link if not logged in
  # 2. a logoff link with the current user name if logged in
  #
  # This view updates when the login state changes
  Views.AuthView = Views.AuthView.extend
    template: SIGN_IN_OUT
    events: _.extend(Views.AuthView.prototype.events,
      'click #save-settings': 'saveSettings'
      'click #fork-book':     'forkBook'
      'click .other-books':   'otherBooks'
    )

    # Add the `canFork` bit to the resulting JSON so the template knows if the
    # current user is the same as the current `repoUser` (Do not show the fork button).
    templateHelpers: ->
      return {canFork: @model.get('id') != @model.get('repoUser') or not @model.get('password')}

    signIn: ->
      # Set the username and password in the `Auth` model
      @model.set
        id:       @$el.find('#github-id').val()
        password: @$el.find('#github-password').val()

    # Clicking on the link will redirect to the logoff page
    # Before it does, update the model
    signOut: -> @model.signOut()

    forkBook: ->
      # Show an alert if the user is not logged in
      return alert 'Please log in to fork or just go to the github page and fork the book!' if not @model.get 'id'

      # Populate the fork modal before showing it
      $fork = @$el.find '#fork-book-modal'


      forkHandler = (org) -> () ->
        Auth.getRepo().fork (err, resp) ->
          # Close the modal dialog
          $fork.modal('hide')

          throw "Problem forking: #{err}" if err

          setTimeout(->
            Auth.set 'repoUser', (org or Auth.get('id'))
          , 10000)

          alert 'Thanks for copying!\nThe current repository (in settings) will be updated to point to your copy of the book. \nThe next time you click Save the changes will be saved to your copied book.\nIf not, refresh the page and change the Repo User in Settings.'


      Auth.getUser().orgs (err, orgs) ->
        $list = $fork.find('.modal-body').empty()

        $item = @$(FORK_BOOK_ITEM {login: Auth.get 'id'})
        $item.find('button').on 'click', forkHandler(null)
        $list.append $item

        _.each orgs, (org) ->
          $item = @$(FORK_BOOK_ITEM {login: "#{org.login} (Organization)"})
          # For now disallow forking to organizations.
          #     $item.find('button').on 'click', forkHandler(org)
          $item.addClass 'disabled'

          $list.append $item


        # Show the modal
        $fork.modal('show')


    otherBooks: (evt) ->
      $config = @$(evt.target)

      # Add a trailing slash to the root path if one is set
      rootPath = $config.data('rootPath')
      rootPath += '/' if rootPath and rootPath[rootPath.length-1] != '/'

      # Close the modal
      $save = @$el.find '#save-settings-modal'
      $save.modal('hide')

      @model.set
        repoUser: $config.data('repoUser')
        repoName: $config.data('repoName')
        branch:   $config.data('branch')
        rootPath: rootPath

    saveSettings: ->
      # Add a trailing slash to the root path if one is set
      rootPath = @$el.find('#github-rootPath').val()
      rootPath += '/' if rootPath and rootPath[rootPath.length-1] != '/'

      # Update the repo settings
      @model.set
        repoUser: @$el.find('#github-repoUser').val()
        repoName: @$el.find('#github-repoName').val()
        branch:   @$el.find('#github-branch').val()
        rootPath: rootPath
