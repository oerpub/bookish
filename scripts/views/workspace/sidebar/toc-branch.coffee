define [
  'jquery'
  'marionette'
  'cs!controllers/routing'
  'cs!helpers/enable-dnd'
  'hbs!templates/workspace/sidebar/toc-branch'
], ($, Marionette, controller, EnableDnD, tocBranchTemplate) ->

  # This class introduces a `renderModelOnly()` method that will
  # re-render only the Model part of the CompositeView.
  #
  # **NOTE**: It requires that the `itemViewContainer` be a child (**not descendant**)
  # in order to work!
  class SmartCompositeView extends Marionette.CompositeView
    initialize: (options) ->

      if @model
        # Trigger a load so a partially populated model may "fill up"
        @model.load?()
        @listenTo @model, 'change', (model, collection, options) => @renderModelOnly()

      if @collection
        # Figure out if the expanded state has changed (see if we need to re-render the model)
        @listenTo @collection, 'add', (model, collection, options) => @renderModelOnly() if @collection.length == 1
        @listenTo @collection, 'remove', (model, collection, options) => @renderModelOnly() if @collection.length == 0

    renderModelOnly: () ->
      # **DO NOT** just detach children. They (and descendants) will
      # lose their draggable events.
      #
      # Instead, reconstruct around the DOM tree

      # Detach the children
      $children = @$el.find(@itemViewContainer).children()

      @triggerBeforeRender()

      $html = $('<div></div>').append(@renderModel())
      # Reattach everything but the children
      # Remove the itemViewContainer
      $html.find(@itemViewContainer).remove()
      $modelNodes = $html.children()
      @$el.children().not(@$el.find(@itemViewContainer)).remove()
      @$el.prepend($modelNodes)

      # the ui bindings is done here and not at the end of render since they
      # will not be available until after the model is rendered, but should be
      # available before the collection is rendered.
      @bindUIElements()
      @triggerMethod('composite:model:rendered')

      @triggerMethod('composite:rendered')
      @triggerRendered()

    render: () ->
      result = super()

      if @model?.expanded
        @$el.addClass('editor-node-expanded')
        @_renderChildren()
      else
        @$el.removeClass('editor-node-expanded')
      return result

    # Override internal Marionette method.
    # This method adds a child list item at a given index.
    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)

    # Toggle expanded/collapsed in the View
    # -------
    #
    # The first time a node is rendered it is collapsed so we lazily load the
    # `ItemView` children.
    #
    # Initially, the node is collapsed and the following occurs:
    #
    # 1. `@render()` calls `@renderChildren()`
    # 2. Since `@isExpanded == false` the children are not rendered
    #
    # When the node is expanded:
    #
    # 1. `@model.expanded` is set to `true`
    # 2. `@render()` is called and calls `@renderChildren()`
    # 3. Since `@model.expanded == true` the children are rendered and attached to the DOM
    # 4. `@hasRendered` is set to `true` so we know not to generate the children again
    #
    #
    # When an expanded node is collapsed:
    #
    # 1. `@model.expanded` is set to `false`
    # 2. A CSS class is set on the `<li>` item to hide children
    # 3. CSS rules hide the children and change the expand/collapse icon
    #
    # When a node that was expanded and collapsed is re-expanded:
    #
    # 1. `@model.expanded` is set to `true`
    # 2. Since `@hasRendered == true` there is no need to call `@render()`
    # 3. The CSS class is removed to show the children again

    # Called from UI when user clicks the collapse/expando buttons
    toggleExpanded: -> @expand(!@model.expanded)

    # Pass in `false` to collapse
    expand: (expanded) ->
      @model.expanded = expanded
      @render()


  return class TocBranchView extends SmartCompositeView
    tagName: 'li'
    itemViewContainer: '> ol'

    initialize: (options) ->
      @template = (data) =>
        data.id = @model.id or @model.cid
        return tocBranchTemplate(data)

      @collection = @model.getChildren?()
      # Brought in by either toc's itemViewOptions or tocBranch's itemViewOptions
      @container = options.container

      super(options)

    # Pass down the Book so we can look up the overridden title
    itemViewOptions: () -> {container: @collection}


    onRender: () ->
      # Add DnD options to content
      EnableDnD.enableContentDnD(@model, @$el.find('> .editor-node-body > *[data-media-type]'))

      if @model.getParent?()
        EnableDnD.enableDropAfter(@model, @model.getParent(), @$el.find('> .editor-drop-zone-after'))

    templateHelpers: () ->
      # For a book, show the ToC unsaved/remotely-changed icons (in the navModel, instead of the OPF file)
      # The cases below are:
      #
      # 1. TocPointerNode
      # 2. OpfFile
      model = @model.dereferencePointer?() or @model.navModel or @model

      return {
        mediaType: @model.mediaType
        isGroup: !!(@model.dereferencePointer?() or @model).getChildren
        hasParent: !! @model.getParent?()
        hasChildren: !! @model.getChildren?()?.length
        isExpanded: @expanded
        # Possibly delegate to the navModel for dirty bits
        _isDirty: model.get('_isDirty')
        _hasRemoteChanges: model.get('_hasRemoteChanges')
      }

    events:
      # The `.editor-node-body` is needed because `li` elements render differently
      # when there is a space between `<li>` and the first child.
      # `.editor-node-body` ensures there is never a space.
      'click > .editor-node-body > .editor-expand-collapse': 'toggleExpanded'
      'click > .editor-node-body > .edit-settings': 'editSettings'
      'click > .editor-node-body .go-edit': 'goEdit'

    goEdit: () ->
      # Edit the model in the context of this folder/book. Explicitly close
      # the picker. This is initiated from here because at this point we're
      # certain that the request to edit was initiated by a click in the
      # toc/picker.
      controller.layout.showWorkspace(false)
      controller.goEdit(@model, @model.getRoot?())


    editSettings: ->
      title = prompt('Edit Title:', @model.getTitle?(@container) or @model.get('title'))
      if title then @model.setTitle?(@container, title) or @model.set('title', title)

      @renderModelOnly()
