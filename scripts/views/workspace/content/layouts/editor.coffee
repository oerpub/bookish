define [
  'marionette'
  'aloha'
  'cs!views/workspace/content/content-edit'
  'hbs!templates/workspace/content/layouts/editor'
], (Marionette, Aloha, ContentEditView, editorTemplate) ->

  return class EditorLayout extends Marionette.Layout
    template: editorTemplate

    regions:
      edit: '#layout-body'

    onRender: () ->
      @edit.show(new ContentEditView({model: @model}))

    onShow: () ->
      # FIXME. Set the title of the edited content. This could likely be
      # done better, and would normally be unnecessary because this info is
      # also in @title above, but presently this is being hidden in css pending
      # other changes, so we need this feedback here.
      @$el.parent().parent().parent().parent().find(
        '#module-title-indicator').text(@model.get('title'))

      @listenTo @model, "change:title", =>
        @$el.parent().parent().parent().parent().find(
          '#module-title-indicator').text(@model.get('title'))

      # Focus the editor. This has to be done here, because @$el isn't attached
      # to the DOM before this. We also have to wait until the content is
      # loaded and the editor is actually activated.
      $.when(@edit.currentView.editorLoaded, @edit.currentView.contentLoaded).done () =>
        alohaEditable = Aloha.getEditableById @edit.currentView.$el.attr('id')
        if alohaEditable
          # Place the cursor at the beginning of the editor
          range = Aloha.createRange()
          range.setStart alohaEditable.obj[0], 0
          range.setEnd alohaEditable.obj[0], 0
          Aloha.getSelection().removeAllRanges()
          Aloha.getSelection().addRange(range)

          #Activate it
          alohaEditable.activate()

          # Update Aloha's idea of the current selection. This is here so any
          # plugin that uses Aloha.Selection will work correctly.
          range = new GENTICS.Utils.RangeObject()
          range.startContainer = range.endContainer = alohaEditable.obj[0]
          range.startOffset = range.endOffset = 0
          Aloha.Selection.rangeObject = range
          Aloha.Selection.updateSelection()

    onClose: () ->
      # Clear the title of the edited content
      @$el.parent().parent().parent().parent().find(
        '#module-title-indicator').text('')
