define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/aloha-edit'
  'hbs!templates/workspace/content/content-edit'
], ($, _, Backbone, Marionette, AlohaEditView, contentEditTemplate) ->

  # Edit Content Body
  # -------
  return AlohaEditView.extend
    # **NOTE:** This template is not wrapped in an element
     template: (serialized_model) -> "#{serialized_model.title or 'Untitled'}"
     modelKey: 'title'
     tagName: 'span' # override the default tagName of `div` so titles can be edited inline.
