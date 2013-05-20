define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!views/workspace/toc'
  'hbs!templates/layouts/workspace/sidebar'
], ($, _, Backbone, Marionette, TocView, sidebarTemplate) ->

  return new (Marionette.Layout.extend
    template: sidebarTemplate

    regions:
      toc: '#workspace-sidebar'

    render: () ->
      Marionette.Layout::render.apply(@, arguments)
      @load()

    load: () ->
      @toc.show(new TocView())
  )()
