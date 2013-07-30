define [
  'marionette'
  'cs!collections/content'
  'hbs!gh-book/auth-template'
  'bootstrapModal'
], (Marionette, allContent, authTemplate) ->

  return class GithubAuthView extends Marionette.ItemView
    template: authTemplate

    events:
      'click #sign-in-ok': 'signIn'
      'click #sign-in': 'signInModal'
      'click #sign-out': 'signOut'
      'click #save-content': 'saveContent'
      'click #fork-content': 'forkContent'


    initialize: () ->
      # When a model has changed (triggered `dirty`) update the Save button
      @listenTo allContent, 'dirty', (model, options) => @setDirty()
      # Update the Save button when new Folder/Book/Module is created (added to `allContent`)
      @listenTo allContent, 'add remove', (model, collection, options) =>
        @setDirty() if not (options.loading or options.parse)


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
      @model.set
        id:       @$el.find('#github-id').val()
        password: @$el.find('#github-password').val()
        token:    @$el.find('#github-token').val()

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
