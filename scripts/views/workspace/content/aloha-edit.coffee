define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'aloha'
  'mathjax'
], ($, _, Backbone, Marionette, Aloha, MathJax) ->

  return Marionette.ItemView.extend
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'You need to specify a template, modelKey, and optionally alohaOptions'
    modelKey: null
    alohaOptions: null

    initialize: ->
      # Update the view when the content is done loading (remove progress bar)
      @listenTo(@model, 'loaded', @render)

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate

        alohaId = @$el.attr('id')
        # Sometimes Aloha hasn't loaded up yet
        if alohaId and @$el.parents()[0]
          alohaEditable = Aloha.getEditableById(alohaId)
          editableBody = alohaEditable.getContents()
          alohaEditable.setContents(value) if value != editableBody
        else
          @$el.empty().append(value)

    onRender: ->
      # Wait until Aloha is started before loading MathJax.
      MathJax?.Hub.Configured()

      if @model.loaded
        # Once Aloha has finished loading enable
        @$el.addClass('disabled')
        Aloha.ready =>
          @$el.aloha(@alohaOptions)
          @$el.removeClass('disabled')

        # Auto save after the user has stopped making changes
        updateModelAndSave = =>
          alohaId = @$el.attr('id')
          # Sometimes Aloha hasn't loaded up yet
          # Only save when the editable has changed
          if alohaId
            alohaEditable = Aloha.getEditableById(alohaId)
            editableBody = alohaEditable.getContents()
            # Change the contents but do not update the Aloha editable area
            @model.set @modelKey, editableBody, {internalAlohaUpdate: true}

        # Grr, the `aloha-smart-content-changed` can only be listened to globally
        # (via `Aloha.bind`) instead of on each editable.
        #
        # This is problematic when we have multiple Aloha editors on a page.
        # Instead, autosave after some period of inactivity.
        @$el.on 'blur', updateModelAndSave
