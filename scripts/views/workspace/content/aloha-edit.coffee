define [
  'jquery'
  'marionette'
  'aloha'
  #'mathjax'
], ($, Marionette, Aloha) ->

  return class AlohaEditView extends Marionette.ItemView
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'BUG: You need to specify a template, modelKey'
    modelKey: null
    aloha: null

    templateHelpers: () ->
      return {isLoaded: @isLoaded}

    initialize: () ->
      @isLoaded = @model.isNew()

      @initialRender = new $.Deferred()
      @contentLoaded = new $.Deferred()
      @modelLoaded = @model.load()
      @editorLoaded = new $.Deferred()

      # When editor is finally created, resolve a promise. This is the same as
      # Aloha.unbind, but avoids race condition.
      $(Aloha, 'body').off('aloha-editable-created.aloha-edit')
      .on 'aloha-editable-created.aloha-edit',  (evt, editable) =>
        @editorLoaded.resolve() if editable.obj.is('.aloha-root-editable')

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate

        if @model.get(@modelKey)?.length
          # FIXME: SHould **not** depend on the state of the promise.
          if 'resolved' == @contentLoaded.state()
            if @model.isDirty()
              console.log('Discarding local changes because of remote commit')
            else
              console.log('Updating local content because of remote changes (but there were no local changes)')
            @render()
          else
            @contentLoaded.resolve()


      # if content is already present change will never fire
      # so check that and conditionally finish the content loading as well
      @modelLoaded.done =>
        @contentLoaded.resolve() if @model.get(@modelKey)?.length

      # this is the trigger for actually showing content and enabling editing
      $.when(@modelLoaded, @contentLoaded, @initialRender).done =>
        @isLoaded = true
        @render()

    # Stop auto-setting when the view closes
    onClose: () ->
      # This is the same as Aloha.unbind, the difference is that Aloha.unbind
      # asks requirejs to load aloha/jquery first, causing the actual unbind
      # to be deferred. Of course, Murhpy's Law dictates that it will only
      # execute after we bound a new handler below, leaving us with no handler
      # at all.
      $(Aloha, 'body').off 'aloha-smart-content-changed.updatemodel'

      # Kill old editable, otherwise they accumulate on Aloha.editables.
      @$el.mahalo?()

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

        # Once Aloha has finished loading enable
        @$el.addClass('disabled')

        Aloha.ready =>
          @$el.addClass('aloha-root-editable')
          @$el.mahalo?()

          # resset some of the state of our root element so aloha doesn't freak out
          @$el.removeClass('aloha-block-blocklevel-sortable')
          @$el.removeData()

          @$el.aloha()

          Aloha.bind 'aloha-smart-content-changed.updatemodel', (evt, d) =>
            updateModel() if d.editable.obj.is(@$el) or $.contains @$el[0], d.editable.obj[0]

          # Wait until Aloha is started before loading MathJax.
          MathJax?.Hub.Configured()

          # reenable everything
          @$el.removeClass('disabled')
      else
        @initialRender.resolve()
