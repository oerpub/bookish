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
    aloha: null

    templateHelpers: () ->
      return {isLoaded: @isLoaded}

    initialize: () ->
      @isLoaded = false

      # images only have to be loaded the first time
      if @model.attributes.body?.length
        @imagesLoaded = (new $.Deferred()).resolve()
      else
        @imagesLoaded = new $.Deferred()

      @initalRender = new $.Deferred()
      @contentLoaded = new $.Deferred()
      @modelLoaded = @model.load()

      $(window).bind 'oer.images.loaded', =>
        $(window).unbind 'oer.images.loaded'
        @imagesLoaded.resolve()

      @listenTo @model, "change:#{@modelKey}", =>
        @contentLoaded.resolve() if @model.attributes.body.length

      # if content is already present change will never fire
      # so check that and conditionally finish the content loading as well
      @modelLoaded.done =>
        @contentLoaded.resolve() if @model.attributes.body.length
     
      # this is the trigger for actually showing content and enabling editing 
      $.when(@imagesLoaded, @modelLoaded, @contentLoaded, @initalRender).done =>
        @isLoaded = true
        @render()

    # Stop auto-setting when the view closes
    onClose: () ->
      clearInterval(@saveInterval)
      @saveInterval = null

    onRender: () ->
      # update model after the user has stopped making changes
      
      if @isLoaded
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

      @initalRender.resolve()
