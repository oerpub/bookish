define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/layouts/workspace'
  'aloha'
  'bootstrapDropdown'
], ($, _, Backbone, Marionette, workspaceTemplate) ->

  return new (Marionette.Layout.extend
    template: workspaceTemplate

    regions:
      menu: '#menu'
      sidebar: '#sidebar'
      content: '#content'
  )()
