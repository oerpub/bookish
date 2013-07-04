# Tree Mixin
# =======
#
# This provides models to behave like a Tree Node.
#
# Features:
# - trickles up events like `tree:add tree:remove tree:change`
# - defers construction of new nodes when they are dropped to the root
# - works when moving from one tree to another
#
# **Note:** Instance variables used by this mixin are prefixed with `_tree_`
define ['backbone'], (Backbone) ->

  treeMixin =

    initializeTreeHandlers: (options) ->
      throw 'BUG: Missing constructor options' if not options
      throw 'BUG: Missing root' if not options.root
      #throw 'BUG: Missing title or model' if not options.title

      @_tree_root = options.root

      @_tree_children = new Backbone.Collection()

      @_tree_children.on 'add', (child, collection, options) =>
        # Parent is useful for DnD but since we don't use a `TocNode`
        # for the leaves (`Module`) the view needs to pass the
        # model in anyway, so it's commented.
        #

        # Remove the child if it is already attached somewhere
        child._tree_parent.removeChild(child) if child._tree_parent

        child._tree_parent = @
        child._tree_root = @_tree_root
        @trigger 'tree:add', child, collection, options

      @_tree_children.on 'remove', (child, collection, options) =>
        delete child._tree_parent
        delete child._tree_root
        @trigger 'tree:remove', child, collection, options

      @_tree_children.on 'change', (child, collection, options) =>
        @trigger 'tree:change', child, collection, options

      trickleEvents = (name) =>
        @_tree_children.on name, (model, collection, options) =>
          @trigger name, model, collection, options

      # Trickle up tree change events so the Navigation HTML
      # updates when the nodes or title changes
      trickleEvents 'tree:add'
      trickleEvents 'tree:remove'
      trickleEvents 'tree:change'


    newNode: (options) -> throw 'BUG: Only the root can create new Pointer Nodes'

    getParent: () -> @_tree_parent
    getChildren: () -> @_tree_children

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

      # Before adding the model make sure it's a Tree Node (does it have `._children`.
      # If not, wrap it in a node
      if ! (model._tree_children)
        model = @_tree_root.newNode {model:model}

      children.add(model, {at:at})
      # When moving from one book to another make sure the root is set
      model._tree_root = @_tree_root


  return treeMixin
