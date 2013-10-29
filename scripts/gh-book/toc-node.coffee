define [
  'backbone'
  'underscore'
  'jquery'
  'cs!collections/content'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/uuid'
  'cs!models/content/inherits/saveable'
  'cs!mixins/tree'
], (Backbone, _, $, allContent, XhtmlFile, uuid, SaveableModel, treeMixin, Path) ->
  'models/path'

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

    # Prevent the asterisk since TocNode elements are not actually Saveable (but OPF is)
    # TODO: Fix this once the editor can create new OPF files
    isNew: () -> false

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

            # In order to place the new content in the same "book", we name it
            # relative to the navmodel. That is, the new content will be
            # dropped next to whatever document is the navmodel.
            srcPath = Path.dirname(realModel.id)
            dstPath = Path.dirname(root.navModel.id)
            json.id = Path.normpath(dstPath + '/' + uuid())

            if json.body and srcPath != dstPath
              $elements = $(json.body)
              changed = false

              # Look for images in json.body, and rewrite them as
              # appropriate.
              $elements.find('img').each (idx, img) =>
                imgpath = $(img).attr('data-src')
                if not (/^https?:\/\//.test(imgpath) or Path.isabs imgpath)
                  uri = Path.normpath srcPath + '/' + imgpath
                  newuri = Path.relpath(uri, dstPath)
                  $(img).attr('data-src', newuri)
                  changed = true

              # Look for links in json.body and rewrite them
              $elements.find('a').each (idx, link) =>
                linkpath = $(link).attr('href')
                if not (/^https?:\/\//.test(linkpath) or Path.isabs linkpath)
                  uri = Path.normpath srcPath + '/' + linkpath
                  newuri = Path.relpath(uri, dstPath)
                  $(link).attr('href', newuri)
                  changed = true

              if changed
                json.body = _.pluck($elements, (ob) -> ob.outerHTML or '').join('')

            clone = allContent.model(json)
            clone.setNew?()
            allContent.add(clone)
            # Fetch all the images since it is marked as new (already loaded)
            clone.loadImages?() # HACK. SHould make it a promise...

            pointerNode = root.newNode {title:newTitle, model:clone}
            pointerNode.set('title', newTitle)

            super(pointerNode, at)

        else
          # It is a TocNode and cannot be loaded so instead of
          # recursively cloning it (more code to write) just move it.
          super(model, at)

      else
        super(model, at)
