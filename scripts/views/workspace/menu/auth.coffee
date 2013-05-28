define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/menu/sign-in-out'
], ($, _, Backbone, Marionette, signInOutTemplate) ->

  # Default Auth View
  # -------
  # The top-right of each page should have either:
  #
  # 1. a Sign-up/Login link if not logged in
  # 2. a logoff link with the current user name if logged in
  #
  # This view updates when the login state changes
  return Marionette.ItemView.extend
    template: signInOutTemplate
    events:
      'click #sign-out':      'signOut'
      'click #save-content':  'saveContent'

    initialize: ->
      @dirtyModels = new Backbone.Collection()
      # Sort by `id` so new models are saved first.
      # This way their id's change and their references (in books and Folders)
      # will be updated before the Book/Folder is saved.
      @dirtyModels.comparator = 'id'

      # Bind a function to the window if the user tries to navigate away from this page
      beforeUnload = =>
        return 'You have unsaved changes. Are you sure you want to leave this page?' if @hasChanged
      $(window).on 'beforeunload', beforeUnload

      #@listenTo @model, 'change', => @render()
      #@listenTo @model, 'change:userid', => @render()

      # Listen to all changes made on Content so we can update the save button
      ###
      @listenTo Models.ALL_CONTENT, 'change:_isDirty', (model, b,c) =>
        # Figure out if the model was just fetched (all the changed attributes used to be 'undefined')
        # or if the attributes did actually change
        if model.get('_isDirty')
          @dirtyModels.add model
        else
          @dirtyModels.remove model

      @listenTo Models.ALL_CONTENT, 'change:treeNode add:treeNode remove:treeNode', (model, b,c) =>
        @dirtyModels.add model

      @listenTo Models.ALL_CONTENT, 'add', (model) => @dirtyModels.add model if model.get('_isDirty')
      ###

      @listenTo @dirtyModels, 'add reset', (model, b,c) =>
        @hasChanged = true
        $save = @$el.find '#save-content'
        $save.removeClass('disabled')
        $save.addClass('btn-primary')

      @listenTo @dirtyModels, 'remove', (model, b,c) =>
        if @dirtyModels.length == 0
          @hasChanged = false
          $save = @$el.find '#save-content'
          $save.addClass('disabled')
          $save.removeClass('btn-primary')

    onRender: ->
      # Enable tooltips
      #@$el.find('*[title]').tooltip()

    # Clicking on the link will redirect to the logoff page
    # Before it does, update the model
    signOut: -> @model.signOut()

    # Save each model in sequence.
    # **FIXME:** This should be done in a commit batch
    saveContent: ->
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
