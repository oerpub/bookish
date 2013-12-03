define [
  'jquery'
  'marionette'
  'cs!session'
  'cs!collections/content'
  'hbs!templates/workspace/menu/auth'
  'bootstrapTooltip'
], ($, Marionette, session, content, authTemplate) ->

  _hasChanged = false

  # Default Auth View
  # -------
  # The top-right of each page should have either:
  #
  # 1. a Sign-up/Login link if not logged in
  # 2. a logoff link with the current user name if logged in
  #
  # This view updates when the login state changes
  return class AuthView extends Marionette.ItemView
    template: (serializedModel) ->
      return authTemplate
        authenticated: session.authenticated()
        user: session.user()
        changed: _hasChanged

    events:
      'click #sign-out':      'signOut'
      'click #save-content':  'saveContent'

    initialize: () ->
      @listenTo(session, 'login logout', @render)

      # When a model has changed (triggered `dirty`) update the Save button
      @listenTo content, 'change:_isDirty', (model, options) => @changed()
      # Update the Save button when new Folder/Book/Module is created (added to `content`)
      @listenTo content, 'add remove', (model, collection, options) =>
        @changed() if not (options.loading or options.parse)

      # Bind a function to the window if the user tries to navigate away from this page
      $(window).on 'beforeunload', () ->
        return 'You have unsaved changes. Are you sure you want to leave this page?' if _hasChanged

    onRender: () ->
      @$el.html(@template) # FIXME: Why is marionnete not loading the template correctly
      # Enable tooltip
      @$el.find('#save-content').tooltip()

    changed: () ->
      _hasChanged = true
      @render()

    # Clicking on the link will redirect to the logoff page
    # Before it does, update the model
    signOut: -> @model.signOut()

    # Save the collection of media in a single batch
    saveContent: () ->
      console.log 'start saving progress'

      content.save
        success: () =>
          console.log 'end saving progress'
          _hasChanged = false
          @render()
