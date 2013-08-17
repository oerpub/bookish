define [
  'marionette'
  'aloha'
  #'mathjax'
], (Marionette, Aloha) ->

  return class AlohaEditView extends Marionette.ItemView
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'BUG: You need to specify a template, modelKey'
    modelKey: null
    changed: false
    saveInterval: null

    templateHelpers: () ->
      return {isLoaded: @isLoaded}

    initialize: () ->
      @isLoaded = false

      @model.load().done () =>
        @isLoaded = true
        @render() if @changed

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate
        @changed = true

    onRender: () ->
      # update model after the user has stopped making changes

      if @model.attributes.body
        @$el.empty().append(@model.attributes.body) if @$el.find('.progress').length

        updateModel = =>
          alohaId = @$el.attr('id')
          alohaEditable = Aloha.getEditableById(alohaId)
       
          if alohaEditable
            editableBody = alohaEditable.getContents()
            # Change the contents but do not update the Aloha editable area
            @model.set(@modelKey, editableBody, {internalAlohaUpdate: true})
       
        @saveInterval = setInterval(updateModel, 250) if not @saveInterval
       

        # Once Aloha has finished loading enable
        @$el.addClass('disabled')
       
        Aloha.ready =>

          @$el.mahalo() if @$el.mahalo
          @$el.aloha()

          # Wait until Aloha is started before loading MathJax.
          MathJax?.Hub.Configured()
       
          # reenable everything
          @$el.removeClass('disabled')


