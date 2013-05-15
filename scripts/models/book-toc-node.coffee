# Book ToC Tree Model
# =======
# The Book editor contains a tree (`BookTocTree`) of nested models `BookTocNode`
# representing the book structure.
#
# Events fire on `BookTocNode` items so their views can be updated but
# `BookTocTree` can be listened to for events that "bubble up" to the root.
#
# Examples include:
#
# - `add:treeNode` when a new node is added somewhere in the tree
# - `remove:treeNode` when a node is removed somewhere in the tree
# - `change:treeNode` when the title or id of a node in the tree has changed
#
# Additionally, each Node has a `.parent` that is updated when it is moved
# (used by Views to remove/detach a node).

define [
  'jquery'
  'underscore'
  'backbone'
  'cs!models/base-model'
], ($, _, Backbone, BaseModel) ->

  # Represents an item in the ToC
  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.container'
    # Recursively include child nodes in the returned JSON
    toJSON: ->
      json = BaseModel::toJSON.apply(@)
      json.children = @_children.toJSON() if @_children.length
      json

    # Return the `id` of the corresponding Content Model represented by this node.
    # This is used to "look up" the original title of content if it has not been
    # Overridden in the book.
    #
    # If it is an `organization` node (no `id`) then just return itself.
    dereference: -> ALL_CONTENT.get(@id) or @

    initialize: ->
      @on 'change', => @trigger 'change:treeNode'

      # If the Tree Node is initialized with a `children` property
      # then use that config to recursively create new child nodes.
      children = @get 'children'
      @unset 'children', {silent:true}

      @_children = new BookTocNodeCollection()

      @_children.on 'add', (child, collection, options) =>
        child.parent = @
        @trigger 'add:treeNode', child, @, options
      @_children.on 'remove', (child, collection, options) =>
        delete child.parent
        @trigger 'remove:treeNode', child, @, options

      @_children.add children

      # If this node "points to" a piece of content then provide an `editAction`
      if @id
        model = ALL_CONTENT.get(@id)
        @editAction = model.editAction.bind(model) if model

    # Returns the root of this tree node
    root: ->
      root = @
      root = root.parent while root.parent
      root

    accepts: -> [ BaseContent::mediaType, BookTocNode::mediaType, Folder::mediaType ]
    children: -> @_children
    addChild: (model, at=0) ->
      # Move up to the root and see if it's already in the tree
      root = @root()
      children = model.children()

      # If the model is a Folder create a `BookTocNode` and add all the valid children to it
      if Folder::mediaType == model.mediaType
        model = new BookTocNode {title: model.get 'title'}

      # If the model is not already a `BookTocNode` then wrap it in one
      if BookTocNode::mediaType != model.mediaType
        model = new BookTocNode {id: model.id}


      # Model can be a node that points to a piece of content (has `id`) or an
      # internal node (chapter) that is just a container (has `cid`)
      if root.descendants
        shortcut = root.descendants.get(model.id) or root.descendants.get(model.cid)
        if shortcut
          # If `model` is already in `parent.children()` then we are reordering.
          # By removing the model, we need to adjust the index where it will be
          # added.
          if @ == shortcut.parent
            if @children().indexOf(shortcut) < at
              at = at - 1
          shortcut.parent.children().remove(shortcut)
          model = shortcut
        else
          # The model belongs to a different book/folder so clone it.
          # Since children will be added later, don't use the full `.toJSON()`.
          json = model.toJSON()
          delete json.children

          model = new BookTocNode json
      # Set the `parent` in the options so we can rerender the parent in the view
      # (for lazy redrawing)
      options = {parent: @}
      options.at = at if at >= 0
      @_children.add model, options

      root.descendants.add model, {parent:@}
      # Finally, add the children (so the descendants list is populated)
      if children
        children.each (child) -> model.addChild child if child.mediaType in model.accepts()
