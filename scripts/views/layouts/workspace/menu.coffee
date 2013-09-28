define [
  'marionette'
  'cs!collections/media-types'
  'cs!controllers/routing'
  'cs!session'
  'cs!views/workspace/menu/add'
  'cs!views/workspace/menu/toolbar-aloha'
  'hbs!templates/layouts/workspace/menu'
], (Marionette, mediaTypes, controller, session, AddView, toolbarView, menuTemplate) ->

  _toolbar = null

  return new class MenuLayout extends Marionette.Layout
    template: menuTemplate

    events:
      'click .go-workspace': 'goWorkspace'

    goWorkspace: () -> controller.goWorkspace()

    regions:
      toolbar: '#workspace-menu-toolbar'

    onRender: () ->
      @showView(_toolbar)

    showView: (view) ->
      _toolbar = view or toolbarView

      if _toolbar != @toolbar.currentView
        @toolbar.show(_toolbar)

    showToolbar: (view) ->
      @showView(view or toolbarView)
