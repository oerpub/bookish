define [
  'jquery'
  'marionette'
  'cs!collections/media-types'
  'cs!views/workspace/menu/add'
  'cs!views/workspace/sidebar/toc'
  'hbs!templates/layouts/workspace/sidebar'
  'filtered-collection'
], ($, Marionette, mediaTypes, AddView, TocView, sidebarTemplate) ->

  return class Sidebar extends Marionette.Layout
    template: sidebarTemplate

    initialize: () ->
      @filteredMediaTypes = new Backbone.FilteredCollection(null, {collection:mediaTypes})

    regions:
      addContent: '.add-content'
      toc: '.workspace-sidebar'

    events:
      'click .handle': () -> @$el.parent().toggleClass('minimized')

    onShow: () ->
      model = @model
      collection = @collection or model.getChildren()

      if model
        # This is a tree sidebar
        @filteredMediaTypes.setFilter (type) -> return type.id in model.accept
      else
        # This is the Picker/Roots Sidebar
        collection = new Backbone.FilteredCollection(null, {collection:collection})
        collection.setFilter (content)  -> return content.getChildren

      # TODO: Make the collection a FilteredCollection that only shows @model.accepts
      @addContent.show(new AddView {context:model, collection:@filteredMediaTypes})
      @toc.show(new TocView {model:model, collection:collection})

    onWindowResize: () ->

    onRender: () ->
      # Update the width/height of main so we can have Scrollable boxes that vertically stretch the entire page
      $window = $(window)
      $window.on('resize', @onWindowResize.bind(@))
      @onWindowResize()
