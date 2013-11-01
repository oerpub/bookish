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
        @$el.parents('#workspace-container').toggleClass(name+'-minimized')

    onShow: () ->
      model = @model
      collection = @collection or model.getChildren?()

      if model
      else
        @filteredMediaTypes.setFilter (type) -> return type.get('modelType')::toplevel

      # TODO: Make the collection a FilteredCollection that only shows @model.accepts
      @addContent.show(new AddView {context:model, collection:@filteredMediaTypes})
      @toc.show(new TocView {model:model, collection:collection})

    onRender: () ->
      # Update the width/height of main so we can have Scrollable boxes that vertically stretch the entire page
      $window = $(window)

    # Sticking to American spelling here
    maximize: () ->
      name = @$el.parent().attr('id')
      @$el.parents('#workspace-container').removeClass(name+'-minimized')
      return @
