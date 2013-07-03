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
  return class ContentEditView extends AlohaEditView
    modelKey: 'body'

    # **NOTE:** This template is not wrapped in an element
    template: contentEditTemplate
