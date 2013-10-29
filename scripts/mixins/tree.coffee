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
# **Note:** Be sure to call `_initializeTreeHandlers` during `initialize`
# **Note:** Instance variables used by this mixin are prefixed with `_tree_`
define ['backbone'], (Backbone) ->

  treeMixin =

    _initializeTreeHandlers: (options) ->
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
        child._tree_parent.removeChild(child, options) if child._tree_parent and child._tree_parent != @

        child._tree_parent = @
        child._tree_root = @_tree_root
        @trigger 'tree:add', child, collection, options

      @_tree_children.on 'remove', (child, collection, options) =>
        delete child._tree_parent
        delete child._tree_root
        @trigger 'tree:remove', child, collection, options

      @_tree_children.on 'change', (child, options) =>
        # Send 3 arguments so it matches the same signature
        # as `Collection.add/remove` and `tree:add/tree:remove`.
        @trigger 'tree:change', child, @_tree_children, options

      trickleEvents = (name) =>
        @_tree_children.on name, (model, collection, options) =>
          @trigger name, model, collection, options

      # Trickle up tree change events so the Navigation HTML
      # updates when the nodes or title changes
      trickleEvents 'tree:add'
      trickleEvents 'tree:remove'
      trickleEvents 'tree:change'


    newNode: (options) ->
      throw new Error 'BUG: Only the root can create new Pointer Nodes' if @ == @getRoot()
      throw new Error 'BUG: Subclass must implement this method'

    getParent:   () -> @_tree_parent
    getChildren: () -> @_tree_children or throw 'BUG! This node has no children. Call _initializeTreeHandlers ?'

    # Perform a Breadth First Search, returning the first element that matches
    findDescendantBFS: (compare) ->
      #Check children first and then descendants
      return @getChildren().find(compare) or @getChildren().find (node) -> node.findDescendantBFS(compare)

    # Perform a Depth First Search, returning the first element that matches
    findDescendantDFS: (compare) ->
      # Base case
      return @ if compare(@)
      # Search through the children. If one is found that matches
      # then stop searching and return it (bubbling it up)
      ret = null
      # Not as simple as: `@getChildren().find (node) -> node.findDescendantDFS(compare)`
      # because `.find` returns the element, not what was returned to find
      @getChildren().each (node) ->
        return if ret # if something is found, stop searching
        found = node.findDescendantDFS(compare)
        ret = found
      return ret

    getRoot: () ->
      root = null
      parent = @
      while parent = parent.getParent()
        root = parent
      return root

    removeChild: (model, options) ->
      children = @getChildren()
      throw 'BUG: child is not in this node' if not (children.contains(model) or children.get(model.id))
      model = children.get(model.id) if !children.contains(model)
      children.remove(model, options)

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
        realModel._tree_parent = null

      # Before adding the model make sure it's a Tree Node (does it have `._tree_children`.
      # If not, wrap it in a node
      if ! (model._tree_children)
        model = @_tree_root.newNode {model:model}

      children.add(model, {at:at})
      # When moving from one book to another make sure the root is set
      model._tree_root = @_tree_root


  return treeMixin
