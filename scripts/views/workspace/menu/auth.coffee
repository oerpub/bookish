define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'session'
  'cs!collections/content'
  'hbs!templates/workspace/menu/auth'
  'bootstrapTooltip'
], ($, _, Backbone, Marionette, session, content, authTemplate) ->

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
      @listenTo(content, 'add remove', @changed)
      @listenTo content, 'change', (model, options) =>
        # A change event can occur (ie setting a title during parsing but the changed set is still empty)
        @changed() if model.hasChanged()

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

      ###
      return alert 'You need to Sign In (and make sure you can edit) before you can save changes' if not @model.get 'id'
      $save = @$el.find('#save-progress-modal')
      $saving     = $save.find('.saving')
      $alertError = $save.find('.alert-error')
      $successBar = $save.find('.progress > .bar.success')
      $errorBar   = $save.find('.progress > .bar.error')
      $label = $save.find('.label')

      total = @dirtyModels.length
      errorCount = 0
      finished = false

      recSave = =>
        $successBar.width(((total - @dirtyModels.length - errorCount) * 100 / total) + '%')
        $errorBar.width((  errorCount                                 * 100 / total) + '%')

        if @dirtyModels.length == 0
          if errorCount == 0
            finished = true
            $save.modal('hide')
          else
            $alertError.removeClass 'hide'

        else
          model = @dirtyModels.first()
          $label.text(model.get('title'))

          # Clear the changed bit since it is saved.
          #     delete model.changed
          #     saving = true; recSave()
          saving = model.save null,
              success: =>
                # Clear the dirty bit for the model
                model.set {_isDirty:false}
                recSave()
              error: -> errorCount += 1
          if not saving
            console.log "Skipping #{model.id} because it is not valid"
            recSave()

      $alertError.addClass('hide')
      $saving.removeClass('hide')
      $save.modal('show')
      recSave()

      # Only show the 'Saving...' alert box if the save takes longer than 2 seconds
      setTimeout(->
        if total and (not finished or errorCount)
          $save.modal('show')
          $alertError.removeClass('hide')
          $saving.addClass('hide')
      , 2000)
    ###
