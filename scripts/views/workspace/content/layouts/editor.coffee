define [
  'marionette'
  'cs!views/workspace/content/content-edit'
  'cs!views/workspace/content/edit-title'
  'cs!views/workspace/content/layouts/edit-metadata'
  'cs!views/workspace/content/edit-roles'
  'hbs!templates/workspace/content/layouts/editor'
], (Marionette, ContentEditView, TitleView, MetadataLayout, RolesView, editorTemplate) ->

  return class EditorLayout extends Marionette.Layout
    template: editorTemplate

    regions:
      title: '#layout-title'
      metadata: '#layout-metadata'
      roles: '#layout-roles'
      edit: '#layout-body'

    onRender: () ->
      @title.show(new TitleView({model: @model}))
      @metadata.show(new MetadataLayout({model: @model}))
      @roles.show(new RolesView({model: @model}))
      @edit.show(new ContentEditView({model: @model}))
