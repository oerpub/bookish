define [
  'jquery'
  'underscore'
  'marionette'
  'cs!models/content/toc-node'
  'cs!controllers/routing'
  'cs!helpers/enable-dnd'
  'cs!collections/content'
  'hbs!templates/workspace/sidebar/toc-branch'
], ($, _, Marionette, TocNode, controller, EnableDnD, allContent, tocBranchTemplate) ->


  PRETTY_NAMES = {
    'application/oebps-package+xml': 'book'
    'application/xhtml+xml': 'module'

    'application/vnd.org.cnx.collection': 'book'
    'application/vnd.org.cnx.folder': 'folder'
    'application/vnd.org.cnx.module': 'module'
  }

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
    itemViewOptions: () ->
      model = @model.dereferencePointer?() or @model
      {
        container: @collection
        isPicker: @options.isPicker
        ancestorSelected: model.get('_selected') || @options.ancestorSelected
      }

    onRender: () ->
      # Dereference if the model is a pointer-node
      model = @model.dereferencePointer?() or @model

      @$el.toggleClass('active', !!model.get('_selected') && !@options.ancestorSelected)

      # if the user hasn't set the state yet make sure the active file is visible
      if @model.expanded == undefined
        hasDescendant = @model.findDescendantBFS? (child) ->
          # Dereference if the child is a pointer-node
          child = child.dereferencePointer?() or child
          return child.get('_selected')

        @model.expanded = true if hasDescendant

      # Add DnD options to content
      $dropNode = @$el.find('> .editor-node-body')
      $dragNode = $dropNode.find('> *[data-media-type]')
      EnableDnD.enableContentDnD(@model, $dragNode, $dropNode)

      if @model.getParent?()
        EnableDnD.enableDropAfter(@model, @model.getParent(), @$el.find('> .editor-drop-zone-after'))

    prettyName: () ->
      # Translate the mediaType attribute to something nice we can display.
      # FIXME: If we ever need to translate this, is this a good idea?
      return PRETTY_NAMES[@model.mediaType] or 'UNKNOWN_PRETTY_NAME'

    templateHelpers: () ->
      # For a book, show the ToC unsaved/remotely-changed icons (in the navModel, instead of the OPF file)
      # The cases below are:
      #
      # 1. TocPointerNode
      # 2. OpfFile
      modelOrNav = @model.dereferencePointer?() or @model.navModel or @model
      model = @model.dereferencePointer?() or @model

      return {
        isPicker: @options.isPicker
        childIsSelected: @model.findDescendantBFS? (child) -> (child.dereferencePointer?() or child).get('_selected')
        selected: model.get('_selected')
        ancestorSelected: @options.ancestorSelected
        mediaType: model.mediaType
        isGroup: !! model.getChildren
        canEditMetadata: !! @model.triggerMetadataEdit?
        hasParent: !! @model.getParent?()
        hasChildren: !! @model.getChildren?()?.length
        isExpanded: @expanded
        canRemove: !! @model.removeMe
        # Possibly delegate to the navModel for dirty bits
        _isDirty: modelOrNav.get('_isDirty')
        _hasRemoteChanges: modelOrNav.get('_hasRemoteChanges')
        prettyName: @prettyName()
      }

    events:
      # The `.editor-node-body` is needed because `li` elements render differently
      # when there is a space between `<li>` and the first child.
      # `.editor-node-body` ensures there is never a space.
      'click > .editor-node-body > .toggle-expand': 'toggleExpanded'
      'click > .editor-node-body .go-edit': 'goEdit'
      'click > .editor-node-body .delete-module': 'deleteModule'
      'click > .editor-node-body .edit-settings-rename': 'editSettings'
      'click > .editor-node-body .edit-settings-edit': 'goEdit'
      'click > .editor-node-body .edit-settings-metadata': 'editMetadata'

    editMetadata: (e) ->
      e.preventDefault()
      model = @model.dereferencePointer?() or @model
      model.triggerMetadataEdit?()

    deleteModule: (e) ->
      e.preventDefault()
      return if not confirm('Are you sure you want to delete this?')

      if @model.removeMe
        model = @model.dereferencePointer?() or @model
        parent = @model.getParent()
        parent = parent?.dereferencePointer?() or parent
        root = @model.getRoot?()

        @model.removeMe()

        # If the model we're deleting is selected, or any child node inside it
        # is selected, we need to open the nearest alternative node instead
        if model.get('_selected') or model.findDescendantBFS?((child) -> (child.dereferencePointer?() or child).get('_selected'))

          if parent
            # node has a parent, find the first child of the node and edit it. if the parent
            # is now empty module pane will be emptied as well
            next = parent.findDescendantDFS((model) -> return model.getChildren().isEmpty())
            controller.goEdit(next, root)
          else
            # redirect to first book. The .without() is necessary because
            # OpfFile::removeMe requires EpubContainer on the fly and this
            # causes the delete operation to be async, which means at this
            # point in the code the book might not be deleted yet, which breaks
            # things when you delete the first book.
            firstBook = _.find allContent.without(this.model), (m) ->
              m instanceof TocNode
            controller.goEdit(firstBook, firstBook)

    goEdit: () ->
      # Edit the model in the context of this folder/book. Explicitly close
      # the picker. This is initiated from here because at this point we're
      # certain that the request to edit was initiated by a click in the
      # toc/picker.
      model = @model
      if not model.getRoot?()
        # Find the 1st leaf node (editable model)
        model = model.findDescendantDFS? (model) -> return model.getChildren().isEmpty()
        # if @model does not have `.findDescendantDFS` then use the original model
        model = model or @model

      controller.goEdit(model, model.getRoot?())


    editSettings: ->
      # Use `.toJSON().title` instead of `.get('title')` to support
      # TocPointerNodes which inherit their title if it is not overridden
      title = prompt('Edit Title:', @model.toJSON().title)
      if title and title != @model.toJSON().title
        @model.set('title', title)

      @renderModelOnly()
