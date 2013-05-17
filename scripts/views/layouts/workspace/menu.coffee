define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/auth'
  'cs!views/workspace/add'
  'hbs!templates/layouts/workspace/menu'
], ($, _, Backbone, Marionette, AuthView, AddView, menuTemplate) ->

  return new (Marionette.Layout.extend
    template: menuTemplate

    regions:
      add: '#workspace-menu-add'
      auth: '#workspace-menu-auth'

    render: () ->
      Marionette.Layout::render.apply(@, arguments)
      @load()

    load: () ->
      @add.show(new AddView())
      @auth.show(new AuthView())
  )()
