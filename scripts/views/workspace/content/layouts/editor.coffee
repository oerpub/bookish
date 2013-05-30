define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/content-edit'
  'cs!views/workspace/content/edit-metadata'
  'cs!views/workspace/content/edit-roles'
  'hbs!templates/workspace/content/layouts/editor'
], ($, _, Backbone, Marionette, ContentEditView, MetadataView, RolesView, editorTemplate) ->

  return Marionette.Layout.extend
    template: editorTemplate

    regions:
      metadata: '#layout-metadata'
      roles: '#layout-roles'
      edit: '#layout-body'

    onRender: () ->
      @metadata.show(new MetadataView({model: @model}))
      #@roles.show(new RolesView())
      #@edit.show(new ContentEditView())
