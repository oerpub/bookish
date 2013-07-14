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


    initialize: () ->
      @listenTo allContent, 'add remove', (model, collection, options) =>
        @setDirty() if not (options.loading or options.parse)
      @listenTo allContent, 'change', (model, options) =>
        # A change event can occur (ie setting a title during parsing but the changed set is still empty)
        @setDirty() if model?.hasChanged() and not (options.loading or options.parse)

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
      @model.set
        password: null
        token:    null

      @render()

    # Save the collection of media in a single batch
    saveContent: () ->
      allContent.save().done () =>
        @isDirty = false
        @render()
