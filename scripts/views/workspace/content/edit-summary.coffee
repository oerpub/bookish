define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/aloha-edit'
], ($, _, Backbone, Marionette, AlohaEditView) ->

  return AlohaEditView.extend
    # **NOTE:** This template is not wrapped in an element
     template: (serializedModel) ->
       return "#{serializedModel.summary or 'Enter a summary here'}"
     modelKey: 'summary'
