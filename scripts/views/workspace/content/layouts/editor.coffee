define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/content/layouts/editor'
], ($, _, Backbone, Marionette, editorTemplate) ->

  return Marionette.Layout.extend
    template: editorTemplate

    regions:
      metadata: '#workspace-content-metadata'
      roles: '#workspace-content-roles'
      edit: '#workspace-content-toolbar'

    onRender: () ->
      #@metadata.show(new AddView())
      #@roles.show(new AuthView())
      #@edit.show(new ToolbarView())
