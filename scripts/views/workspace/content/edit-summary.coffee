define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/aloha-edit'
], ($, _, Backbone, Marionette, AlohaEditView) ->

  return class EditSummaryView extends AlohaEditView
    # **NOTE:** This template is not wrapped in an element
     template: (serializedModel) ->
       return "#{serializedModel.summary or ''}"
     modelKey: 'summary'
