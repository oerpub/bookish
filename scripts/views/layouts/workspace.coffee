define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/layouts/workspace'
  'less!styles/main.less'
], ($, _, Backbone, Marionette, workspaceTemplate) ->

  return new (Backbone.Marionette.Layout.extend
    template: workspaceTemplate
    el: 'body'

    regions:
      menu: '#menu'
      sidebar: '#sidebar'
      main: '#main'
  )()
