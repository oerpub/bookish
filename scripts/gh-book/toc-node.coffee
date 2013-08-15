define [
  'backbone'
  'cs!collections/content'
  'cs!gh-book/xhtml-file'
  'cs!models/content/inherits/saveable'
  'cs!mixins/tree'
], (Backbone, allContent, XhtmlFile, SaveableModel, treeMixin) ->

  mediaType = 'application/vnd.org.cnx.section'

  # Mixin the tree before so TocNode can override `addChild`
  SaveableTree = SaveableModel.extend(treeMixin)

  return class TocNode extends SaveableTree # Extend SaveableModel so you can get the isDirty for saving

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      super(options)
      @set 'title', options.title, {parse:true}
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, value, options) =>
        @trigger 'tree:change', model, @, options

      @_initializeTreeHandlers(options)

    # Views rely on the mediaType to be set in here
    # TODO: Fix it in the view's `templateHelpers`
    toJSON: () ->
      json = super()
      json.mediaType = @mediaType
      return json

    # Defined in `mixins/tree`
    addChild: (model, at) ->
      # Clone if moving between two books
      # If `model` is a pointer (probably) then
      #
      # 1. Clone the underlying Content model (XHTMLFile)
      # 2. Create a new PointerNode
      # 3. Set the title of the new PointerNode to be "Copy of #{title}"

      root = @getRoot() or @
      modelRoot = model.getRoot?() # Case of dropping a book onto a folder... `or model`

      if root and modelRoot and root != modelRoot
        # If it is a pointer then dereference it
        title = model.get('title')
        realModel = model.dereferencePointer?() or model

        # At this point realModel can be a XhtmlFile or a TocNode (section).
        # If it is a Loadable (XhtmlFile) then load it and make a copy.
        # Otherwise, just move it.

        if realModel.load
          # To clone the content, load it first
          realModel.load()
          .fail(() => alert "ERROR: Problem loading #{realModel.id}. Try again later or refresh.")
          .done () =>
            newTitle = "Copy of #{title}"
            json = realModel.toJSON()
            json.title = newTitle
            delete json.id

            clone = allContent.model(json)
            allContent.add(clone)

            pointerNode = root.newNode {title:newTitle, model:clone}
            pointerNode.set('title', newTitle)

            super(pointerNode, at)

        else
          # It is a TocNode and cannot be loaded so instead of
          # recursively cloning it (more code to write) just move it.
          super(model, at)

      else
        super(model, at)
