define [
  'cs!views/workspace/content/aloha-edit'
  'hbs!templates/workspace/content/content-edit'
], (AlohaEditView, contentEditTemplate) ->

  # Edit Content Body
  # -------
  return class ContentEditView extends AlohaEditView
    modelKey: 'body'

    # **NOTE:** This template is not wrapped in an element
    template: contentEditTemplate
