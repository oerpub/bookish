define [
  'marionette'
  'aloha'
  #'mathjax'
], (Marionette, Aloha) ->

  AUTOSAVE_INTERVAL = 500 # ms

  return class AlohaEditView extends Marionette.ItemView
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'BUG: You need to specify a template, modelKey'
    modelKey: null
    saveInterval: null

    templateHelpers: () ->
      return {isLoaded: @isLoaded}

    initialize: () ->
      @isLoaded = false

      @model.load().done () =>
        @isLoaded = true
        @render()

        @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
          return if options.internalAlohaUpdate
          @render()

    # Stop auto-setting when the view closes
    onClose: () ->
      clearInterval(@saveInterval)
      @saveInterval = null

    onRender: () ->
      # update model after the user has stopped making changes

      if @model.attributes.body
        updateModel = =>
          alohaId = @$el.attr('id')
          alohaEditable = Aloha.getEditableById(alohaId)
       
          if alohaEditable
            editableBody = alohaEditable.getContents()
            editableBody = editableBody.trim() # Trim for idempotence
            # Change the contents but do not update the Aloha editable area
            @model.set(@modelKey, editableBody, {internalAlohaUpdate: true})
       
        @saveInterval = setInterval(updateModel, AUTOSAVE_INTERVAL) if not @saveInterval
       
       
        # Once Aloha has finished loading enable
        @$el.addClass('disabled')
       
        Aloha.ready =>
       
          @$el.mahalo?()
          @$el.aloha()
       
          # Wait until Aloha is started before loading MathJax.
          MathJax?.Hub.Configured()
       
          # reenable everything
          @$el.removeClass('disabled')
