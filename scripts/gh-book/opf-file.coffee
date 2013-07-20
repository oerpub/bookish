define [
  'backbone'
  'cs!collections/media-types'
  'cs!collections/content'
  'cs!mixins/loadable'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/toc-node'
  'cs!gh-book/toc-pointer-node'
  'cs!gh-book/utils'
], (Backbone, mediaTypes, allContent, loadable, XhtmlFile, TocNode, TocPointerNode, Utils) ->

  class PackageFile extends TocNode
    serializer = new XMLSerializer()

    mediaType: 'application/oebps-package+xml'
    accept: [XhtmlFile::mediaType, TocNode::mediaType]

    branch: true # This element will show up in the sidebar listing

    initialize: () ->
      super {root:@}

      # Contains all entries in the OPF file (including images)
      @manifest = new Backbone.Collection()
      # Contains all items in the ToC (including internal nodes like "Chapter 3")
      @tocNodes = new Backbone.Collection()
      @tocNodes.add @

      # Use the `parse:true` option instead of `loading:true` because
      # Backbone sets this option when a model is being parsed.
      # This way we can ignore firing events when Backbone is parsing as well as
      # when we are internally updating models.
      setNavModel = (options) =>
        if not options.doNotReparse
          options.doNotReparse = true
          @navModel.set 'body', @_serializeNavModel(), options

      @tocNodes.on 'tree:add',    (model, collection, options) => @tocNodes.add model, options
      @tocNodes.on 'tree:remove', (model, collection, options) => @tocNodes.remove model, options

      @getChildren().on 'tree:change add remove', (model, collection, options) =>
        setNavModel(options)
      @getChildren().on 'change reset', (collection, options) =>
        # HACK: `?` is because `inherits/container.add` calls `trigger('change')`
        setNavModel(options)

      @load()


    _loadComplex: (fetchPromise) ->
      fetchPromise
      .then () =>
        # Clear that anything on the model has changed
        @changed = {}
        return @navModel.load()
      .then () =>
        @_parseNavModel()
        @listenTo @navModel, 'change:body', (model, value, options) =>
          @_parseNavModel() if not options.doNotReparse


    _parseNavModel: () ->
      $body = $(@navModel.get 'body')
      $body = $('<div></div>').append $body


      # Generate a tree of the ToC
      recBuildTree = (collection, $rootOl, contextPath) =>
        $rootOl.children('li').each (i, li) =>
          $li = $(li)

          # Remember attributes (like `class` and `data-`)
          attributes = Utils.elementAttributes $li

          # If the node contains a `<span>` then it is a container node
          # If the node contains a `<a>` then we currently only support them as leaves
          $a = $li.children('a')
          $span = $li.children('span')
          $ol = $li.children('ol')
          if $a[0]
            # Look up the href and add the piece of content
            title = $a.text()
            href = $a.attr('href')

            path = Utils.resolvePath(contextPath, href)
            contentModel = allContent.get path

            # Set all the titles of models in the workspace based on the nav tree
            # XhtmlModel titles are not saved anyway.
            contentModel.set 'title', title, {parse:true} if not contentModel.get('title')

            model = @newNode {title: title, htmlAttributes: attributes, model: contentModel}

            collection.add model, {doNotReparse:true}

          else if $span[0]
            model = new TocNode {title: $span.text(), htmlAttributes: attributes, root: @}

            # Recurse and then add the node. that way we reduce the number of notifications
            recBuildTree(model.getChildren(), $ol, contextPath) if $ol[0]
            collection.add model, {doNotReparse:true}

          else throw 'ERROR: Invalid Navigation Tree Structure'

          # Add the model to the tocNodes so we can listen to changes and update the ToC HTML
          @tocNodes.add model, {doNotReparse:true}


      $root = $body.find('nav > ol')
      @tocNodes.reset [@], {doNotReparse:true}
      @getChildren().reset([], {doNotReparse:true})
      recBuildTree(@getChildren(), $root, @navModel.id)


    _serializeNavModel: () ->
      $body = $(@navModel.get 'body')
      $wrapper = $('<div></div>').append $body
      $nav = $wrapper.find 'nav'
      $nav.empty()

      $navOl = $('<ol></ol>')

      recBuildList = ($rootOl, model) =>
        $li = $('<li></li>')
        $rootOl.append $li

        switch model.mediaType
          when XhtmlFile::mediaType
            path = Utils.relativePath(@navModel.id, model.id)
            $node = $('<a></a>')
            .attr('href', path)
          else
            $node = $('<span></span>')
            $li.attr(model.htmlAttributes or {})

        title = model.getTitle?() or model.get 'title'
        $node.html(title)
        $li.append $node

        if model.getChildren?().first()
          $ol = $('<ol></ol>')
          # recursively add children
          model.getChildren().forEach (child) => recBuildList($ol, child)
          $li.append $ol

      @getChildren().forEach (child) => recBuildList($navOl, child)
      $nav.append($navOl)
      $wrapper[0].innerHTML

    parse: (xmlStr) ->
      return xmlStr if 'string' != typeof xmlStr
      @$xml = $($.parseXML xmlStr)

      # If we were unable to parse the XML then trigger an error
      return model.trigger 'error', 'INVALID_OPF' if not @$xml[0]

      # For the structure of the TOC file see `OPF_TEMPLATE`
      bookId = @$xml.find("##{@$xml.get 'unique-identifier'}").text()

      title = @$xml.find('title').text()

      # The manifest contains all the items in the spine
      # but the spine element says which order they are in

      @$xml.find('package > manifest > item').each (i, item) =>
        $item = $(item)

        # Add it to the set of all content and construct the correct model based on the mimetype
        mediaType = $item.attr 'media-type'
        path = $item.attr 'href'
        model = allContent.model
          # Set the path to the file to be relative to the OPF file
          id: Utils.resolvePath(@id, path)
          mediaType: mediaType
          properties: $item.attr 'properties'

        allContent.add model, {loading:true}
        @manifest.add model

        # If we stumbled upon the special navigation document
        # then remember it.
        if 'nav' == $item.attr('properties')
          @navModel = model

      # Ignore the spine because it is defined by the navTree in EPUB3.
      # **TODO:** Fall back on `toc.ncx` and then the `spine` to create a navTree if one does not exist
      return {title: title, bookId: bookId}

    serialize: () -> serializer.serializeToString(@$xml[0])

    newNode: (options) ->
      model = options.model
      node = @tocNodes.get model.id
      if !node
        node = new TocPointerNode {root:@, model:model}
        #@tocNodes.add node
      return node


    # Change the content view when editing this
    contentView: (callback) ->
      require ['cs!views/workspace/content/search-results'], (View) =>
        view = new View({collection: @getChildren()})
        callback(view)

    # Change the sidebar view when editing this
    sidebarView: (callback) ->
      require ['cs!views/workspace/sidebar/toc'], (View) =>
        view = new View
          collection: @getChildren()
          model: @
        callback(view)


  # Mix in the loadable
  PackageFile = PackageFile.extend loadable
