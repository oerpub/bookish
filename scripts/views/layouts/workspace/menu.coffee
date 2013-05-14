define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!collections/media-types'
  'cs!views/workspace/auth'
  'cs!views/workspace/add'
  'hbs!templates/layouts/workspace/menu'
], ($, _, Backbone, Marionette, mediaTypesCollection, AuthView, AddView, menuTemplate) ->

  return new (Marionette.Layout.extend
    template: menuTemplate

    regions:
      add: '#workspace-menu-add'
      auth: '#workspace-menu-auth'

    load: () ->
      @add.show(new AddView({collection: mediaTypesCollection.asCollection()}))
      @auth.show(new AuthView())
  )()
