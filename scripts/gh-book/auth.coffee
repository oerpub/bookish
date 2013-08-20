define [
  'marionette'
  'cs!collections/content'
  'hbs!gh-book/auth-template'
  'bootstrapModal'
  'bootstrapCollapse'
], (Marionette, allContent, authTemplate) ->

  return class GithubAuthView extends Marionette.ItemView
    template: authTemplate

    events:
      'click #sign-in-ok': 'signIn'
      'click #sign-in': 'signInModal'
      'click #sign-out': 'signOut'
      'click #save-content': 'saveContent'
      'click #fork-content': 'forkContent'
      'click #edit-settings': 'editSettingsModal'
      'click #edit-settings-ok': 'editSettings'
      'submit #login-form': 'signIn'

    initialize: () ->
      # When a model has changed (triggered `dirty`) update the Save button
      @listenTo allContent, 'dirty', (model, options) => @setDirty()
      # Update the Save button when new Folder/Book/Module is created (added to `allContent`)
      @listenTo allContent, 'add remove', (model, collection, options) =>
        @setDirty() if not (options.loading or options.parse)

      @listenTo allContent, 'reset', (collection, options) =>
        # Clear the dirty bit since allContent has been reparsed
        @isDirty = allContent.some (model) -> model.isDirty()


      @listenTo @model, 'change', () => @render()

      # Bind a function to the window if the user tries to navigate away from this page
      $(window).on 'beforeunload', () ->
        return 'You have unsaved changes. Are you sure you want to leave this page?' if @isDirty

      # Since this View is reloaded all the time (whenever a route change occurs)
      # re-set the `isDirty` bit.
      @isDirty = true if allContent.some (model) -> model.isDirty()

    templateHelpers: () ->
      return {
        isDirty: @isDirty
        isAuthenticated: !! (@model.get('password') or @model.get('token'))
      }


    setDirty: () ->
      @isDirty = true
      @render()

    signInModal: () ->
      $modal = @$el.find('#sign-in-modal')

      # The hidden event on #login-advanced should not propagate
      $modal.find('#login-advanced').on 'hidden', (e) => e.stopPropagation()

      # attach a close listener
      $modal.on 'hidden', () => @trigger 'close'

      # Show the modal
      $modal.modal {show:true}


    forkContent: () ->

      if not (@model.get('password') or @model.get('token'))
        alert 'Please Sign In before trying to fork a book'
        return

      @model.getClient().getLogin().done (login) =>
        @model.getRepo()?.fork().done () =>
          @model.set 'repoUser', login

    signIn: () ->
      # Set the username and password in the `Auth` model
      attrs =
        id:       @$el.find('#github-id').val()
        token:    @$el.find('#github-token').val()
        password: @$el.find('#github-password').val()

      if not attrs.password or attrs.token
        alert 'We are terribly sorry but github recently changed so you must login to use their API.\nPlease refresh and provide a password or an OAuth token.'
      else
        @model.set(attrs)
        @render()

        # The 1st time the editor loads up it waits for the modal to close
        # but `render` will hide the modal without triggering 'close'
        @trigger 'close'

    signOut: () ->
      settings =
        auth:     undefined
        id:       undefined
        password: undefined
        token:    undefined
      @model.set settings, {unset:true}

      @render()

    # Save the collection of media in a single batch
    saveContent: () ->
      allContent.save().done () =>
        @isDirty = false
        @render()

    # Show the "Edit Settings" modal
    editSettingsModal: () ->
      $modal = @$el.find('#edit-settings-modal')

      # Show the modal
      $modal.modal {show:true}

    # Edit the current repo settings
    editSettings: () ->
      # Silently clear the settings first.
      # This way listeners are **forced** to update and reload when
      # "Save Settings" is clicked.
      #
      # The reason for **forcing** a reload is because this modal is also shown
      # when there is a connection problem loading the workspace.
      @model.set {repoUser:'', repoName:'', branch:''}, {silent:true}

      @model.set
        repoUser: @$el.find('#repo-user').val()
        repoName: @$el.find('#repo-name').val()
        branch:   @$el.find('#repo-branch').val() # can be '' which means use the default branch
