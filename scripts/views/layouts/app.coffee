define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/layouts/app'
  'less!styles/main.less'
], ($, _, Backbone, Marionette, appTemplate) ->

  return new (Marionette.Layout.extend
    template: appTemplate

    regions:
      menu: '#menu'
      sidebar: '#sidebar'
      main: '#main'
  )()
