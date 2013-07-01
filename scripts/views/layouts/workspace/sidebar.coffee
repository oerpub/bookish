define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/sidebar/toc'
  'hbs!templates/layouts/workspace/sidebar'
], ($, _, Backbone, Marionette, TocView, sidebarTemplate) ->

  return new (class Sidebar extends Marionette.Layout
    template: sidebarTemplate

    regions:
      toc: '#workspace-sidebar'

    onRender: () ->
      @toc.show(new TocView())
  )()
