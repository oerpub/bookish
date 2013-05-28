define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/menu/auth'
  'cs!views/workspace/menu/add'
  'cs!views/workspace/menu/toolbar-search'
  'hbs!templates/layouts/workspace/menu'
], ($, _, Backbone, Marionette, AuthView, AddView, ToolbarView, menuTemplate) ->

  return new (Marionette.Layout.extend
    template: menuTemplate

    regions:
      add: '#workspace-menu-add'
      auth: '#workspace-menu-auth'
      toolbar: '#workspace-menu-toolbar'

    onRender: () ->
      @add.show(new AddView())
      @auth.show(new AuthView())
      @toolbar.show(new ToolbarView())
  )()
