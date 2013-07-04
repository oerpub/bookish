define [
  'backbone'
  'cs!models/content/inherits/container'
  'cs!gh-book/xhtml-file'
], (Backbone, BaseContainerModel, XhtmlFile) ->

  mediaType = 'application/vnd.org.cnx.folder'

  class TocNode extends BaseContainerModel

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      throw 'BUG: Missing constructor options' if not options
      throw 'BUG: Missing root' if not options.root
      #throw 'BUG: Missing title or model' if not options.title

      @root = options.root

      @_children = new Backbone.Collection()

      @set 'title', options.title
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, options) =>
        @trigger 'tree:change', model, @, options

      @_children.on 'add', (child, collection, options) =>
        # Parent is useful for DnD but since we don't use a `TocNode`
        # for the leaves (`Module`) the view needs to pass the
        # model in anyway, so it's commented.
        #

        # Remove the child if it is already attached somewhere
        child.parent.removeChild(child) if child.parent

        child.parent = @
        child.root = @root
        @trigger 'tree:add', child, collection, options

      @_children.on 'remove', (child, collection, options) =>
        delete child.parent
        delete child.root
        @trigger 'tree:remove', child, collection, options

      @_children.on 'change', (child, collection, options) =>
        @trigger 'tree:change', child, collection, options

      trickleEvents = (name) =>
        @_children.on name, (model, collection, options) =>
          @trigger name, model, collection, options

      # Trickle up tree change events so the Navigation HTML
      # updates when the nodes or title changes
      trickleEvents 'tree:add'
      trickleEvents 'tree:remove'
      trickleEvents 'tree:change'


    newNode: (options) -> throw 'BUG: Only the root can create new Pointer Nodes'

    getChildren: () -> @_children
    removeChild: (model) ->
      throw 'BUG: child is not in this node' if not @getChildren().get(model.id)
      @getChildren().remove(model.id)

    addChild: (model, at=0) ->
      children = @getChildren()

      # If `model` is already in `@getChildren()` then we are reordering.
      # By removing the model, we need to adjust the index where it will be
      # added.

      # Don't use `children.contains()` because `model` may be a pointer (only the id's match)
      realModel = children.get(model.id) or children.get(model) # `or` is in there because Chapters do not have an id
      if realModel
        if children.indexOf(realModel) < at
          at = at - 1
        children.remove(realModel)

      # Before adding the model make sure it's a `TocNode`.
      # If not, wrap it in one
      if ! (model instanceof TocNode)
        model = @root.newNode {model:model}

      children.add(model, {at:at})


