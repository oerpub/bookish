define [
  'backbone'
  'underscore'
  'jquery'
  'cs!models/content/toc-node'
  'cs!collections/content'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/uuid'
  'models/path'
], (Backbone, _, $, TocNode, allContent, XhtmlFile, uuid, Path) ->

  mediaType = 'application/vnd.org.cnx.section'

  return class NavTocNode extends TocNode

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

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
        # Use `.toJSON().title` instead of `.get('title')` to support
        # TocPointerNodes which inherit their title if it is not overridden
        title = model.toJSON().title or 'Untitled'

        # If it is a pointer then dereference it
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
