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
          # Find first non-metadata top-level element in the editable
          first = alohaEditable.obj.find('> :not([data-type])').first()[0]

          if first
            # Now do it again, using Aloha rangy wrapper
            range = Aloha.createRange()
            range.setStart first, 0
            range.setEnd first, 0
            Aloha.getSelection().removeAllRanges()
            Aloha.getSelection().addRange(range)


          #Activate the editable
          alohaEditable.activate()

    onClose: () ->
      # Clear the title of the edited content
      @$el.parent().parent().parent().parent().find(
        '#module-title-indicator').text('')
