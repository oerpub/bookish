define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/media-types'
  'cs!session'
  'cs!views/workspace/menu/auth'
  'cs!views/workspace/menu/add'
  'cs!views/workspace/menu/toolbar-search'
  'hbs!templates/layouts/workspace/menu'
], ($, _, Backbone, Marionette, mediaTypes, session, AuthView, AddView, toolbarView, menuTemplate) ->

  _toolbar = null

  return new class MenuLayout extends Marionette.Layout
    template: menuTemplate

    regions:
      add: '#workspace-menu-add'
      auth: '#workspace-menu-auth'
      toolbar: '#workspace-menu-toolbar'

    onRender: () ->
      @showView(_toolbar)

    showView: (view) ->
      _toolbar = view or toolbarView

      @add.show(new AddView {collection:mediaTypes})
      @auth.show(new AuthView {model: session})
      @toolbar.show(_toolbar)

    showToolbar: (view) ->
      @showView(view or toolbarView)
