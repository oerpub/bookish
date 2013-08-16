define [
  'marionette'
  'aloha'
  #'mathjax'
], (Marionette, Aloha) ->

  return class AlohaEditView extends Marionette.ItemView
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'BUG: You need to specify a template, modelKey, and optionally alohaOptions'
    modelKey: null
    alohaOptions: null
    content: null

    templateHelpers: () ->
      return {isLoaded: @isLoaded}

    initialize: () ->
      @isLoaded = false
      @model.load().done () =>
        @isLoaded = true
        @render()

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate
        @content = value
        @render()

    onRender: () ->

      # Once Aloha has finished loading enable
      @$el.addClass('disabled')
      Aloha.ready =>
        # Wait until Aloha is started before loading MathJax.
        MathJax?.Hub.Configured()

        # if aloha is on then disable it 
        @$el.mahalo() if @$el.mahalo

        # reset the contents if necessary
        @$el.empty().append(@content) if @content

        # reenable everything
        @$el.aloha(@alohaOptions)
          .removeClass('disabled')
