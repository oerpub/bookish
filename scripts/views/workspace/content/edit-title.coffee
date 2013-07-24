define ['cs!views/workspace/content/aloha-edit'], (AlohaEditView) ->

  return class EditTitleView extends AlohaEditView
    # **NOTE:** This template is not wrapped in an element
     template: (serializedModel) -> return "#{serializedModel.title or 'Untitled'}"
     modelKey: 'title'
     tagName: 'span' # override the default tagName of `div` so titles can be edited inline.
