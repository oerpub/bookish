define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/aloha-edit'
  'hbs!templates/workspace/content/content-edit'
  'bootstrapPopover'
], ($, _, Backbone, Marionette, AlohaEditView, contentEditTemplate) ->

  # Edit Content Body
  # -------
  return AlohaEditView.extend
    # **NOTE:** This template is not wrapped in an element
    template: contentEditTemplate
    modelKey: 'body'
