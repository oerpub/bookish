define [
  'cs!./toc-node'
  'cs!./toc-pointer-node'
  'cs!./module'
], (TocNode, TocPointerNode, ModuleModel) ->

  mediaType = 'application/vnd.org.cnx.section'

  return class BookTocNode extends TocNode

    mediaType: mediaType
    accept: [mediaType, ModuleModel::mediaType]

    # Defined in `mixins/tree`
    addChild: (model, at) ->

      # Link if moving between two books
      # If `model` is a pointer (probably) then
      #
      # 1. Create a new PointerNode
      # 2. Set the title of the new PointerNode to be PointerNode.get('title')
      #    (if the title was overridden before then it is overridden now too)

      root = @getRoot() or @
      modelRoot = model.getRoot?() # Case of dropping a book onto a folder... `or model`

      if root and modelRoot and root != modelRoot

        # If it is a pointer then dereference it and make a new one (to preserve the overwritten title)
        if model.dereferencePointer
          title = model.get('title')
          realModel = model.dereferencePointer()
          newPointer = new TocPointerNode {model:realModel, root:root, title:title}
          super(newPointer, at)

        else
          # It is a TocNode and cannot be loaded so instead of
          # recursively cloning it (more code to write) just move it.
          super(model, at)

      else
        super(model, at)
