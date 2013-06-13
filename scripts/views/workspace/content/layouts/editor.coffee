define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/content/content-edit'
  'cs!views/workspace/content/edit-title'
  'cs!views/workspace/content/edit-metadata'
  'cs!views/workspace/content/edit-roles'
  'hbs!templates/workspace/content/layouts/editor'
], ($, _, Backbone, Marionette, ContentEditView, TitleView, MetadataView, RolesView, editorTemplate) ->

  return Marionette.Layout.extend
    template: editorTemplate

    regions:
      title: '#layout-title'
      metadata: '#layout-metadata'
      roles: '#layout-roles'
      edit: '#layout-body'
    
    initialize: () ->
      @listenTo(@model, 'change', @render)

    onRender: () ->
      @title.show(new TitleView({model: @model}))
      @metadata.show(new MetadataView({model: @model}))
      @roles.show(new RolesView({model: @model}))
      @edit.show(new ContentEditView({model: @model}))
