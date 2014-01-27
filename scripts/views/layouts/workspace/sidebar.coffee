define [
  'jquery'
  'marionette'
  'cs!collections/media-types'
  'cs!views/workspace/menu/add'
  'cs!views/workspace/sidebar/toc'
  'filtered-collection'
], ($, Marionette, mediaTypes, AddView, TocView) ->


  $window = $(window)

  return class Sidebar extends Marionette.Layout
    initialize: (options) ->
      @filteredMediaTypes = new Backbone.FilteredCollection(null, {collection:mediaTypes})
      @collection = new Backbone.FilteredCollection(null, {collection:@model.getChildren()})

      # Filter the "Add" button by what the model accepts
      @filteredMediaTypes.setFilter (type) => return type.id in @model.accept

    regions:
      addContent: '.add-content'
      toc: '.workspace-sidebar'

    events:
      'click .handle, .boxed-group > h3': () ->
        # what are we?
        name = @$el.parent().attr('id')
        # set minimized class on parent based on element id, this seems really hackish but
        # pending large css refactor is the best thing i can think of
        $('body').toggleClass("#{name}-minimized")

    # Ensure the height of the sidebar is always the height of the window
    onWindowResize: () ->
      height = $window.height()
      @$el.css {height:height}

    onShow: () ->
      # Update the width/height of main so we can have Scrollable boxes that vertically stretch the entire page
      $window.on('resize', @onWindowResize.bind(@))
      @onWindowResize()

      model = @model
      collection = @collection or model.getChildren?()

      # TODO: Make the collection a FilteredCollection that only shows @model.accepts
      @addContent.show(new AddView {context:model, collection:@filteredMediaTypes})
      @toc.show(new TocView {model:model, collection:collection})

    onRender: () ->
      # Add a class on the element so we can style it as a Folder or as a ToC
      if @model
        @$el.attr('data-media-type', @model.mediaType)
      else
        @$el.removeAttr('data-media-type')

    # Sticking to American spelling here
    maximize: () ->
      name = @$el.parent().attr('id')
      $('body').removeClass("#{name}-minimized")
      return @
