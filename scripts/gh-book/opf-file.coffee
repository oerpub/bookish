define [
  'jquery'
  'underscore'
  'backbone'
  'cs!collections/media-types'
  'cs!collections/content'
  'cs!models/content/inherits/container'
  'cs!gh-book/xhtml-file'
  'cs!gh-book/toc-node'
  'cs!gh-book/utils'
], ($, _, Backbone, mediaTypes, allContent, BaseContainerModel, XhtmlFile, TocNode, Utils) ->


  return class PackageFile extends BaseContainerModel
    defaults:
      manifest: null
      title: 'Untitled Book'

    mediaType: 'application/oebps-package+xml'
    accept: [XhtmlFile::mediaType, TocNode::mediaType]


    initialize: () ->
      @manifest = new Backbone.Collection()
      @children = new Backbone.Collection()
      @load()
    load: () ->
      @fetch()
      .fail((err) => throw err)
      .done () =>
        @navModel.fetch()
        .fail((err) => throw err)
        .done () =>
          @parseNavModel()

    parseNavModel: () ->
      $body = $(@navModel.get 'body')
      $body = $('<div></div>').append $body




      # Generate a tree of the ToC
      recBuildTree = (collection, $rootOl, contextPath) =>
        $rootOl.children('li').each (i, li) =>
          $li = $(li)

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
            model = allContent.get path

            model.set 'title', title
            collection.add model

            @listenTo model, 'change:title', () =>
              console.warn 'TODO: BUG: Change the title in the ToC'

          else if $span[0]
            model = new TocNode {title: $span.text()}
            collection.add model

            # Recurse
            recBuildTree(model.getChildren(), $ol, contextPath) if $ol[0]
          else throw 'ERROR: Invalid Navigation Tree Structure'


      $root = $body.find('nav > ol')
      @children.reset()
      recBuildTree(@children, $root, @navModel.id)


    parse: (xmlStr) ->
      return xmlStr if 'string' != typeof xmlStr
      $xml = $($.parseXML xmlStr)

      # If we were unable to parse the XML then trigger an error
      return model.trigger 'error', 'INVALID_OPF' if not $xml[0]

      # For the structure of the TOC file see `OPF_TEMPLATE`
      bookId = $xml.find("##{$xml.get 'unique-identifier'}").text()

      title = $xml.find('title').text()

      # The manifest contains all the items in the spine
      # but the spine element says which order they are in

      $xml.find('package > manifest > item').each (i, item) =>
        $item = $(item)

        # Add it to the set of all content and construct the correct model based on the mimetype
        mediaType = $item.attr 'media-type'
        path = $item.attr 'href'
        model = allContent.model
          # Set the path to the file to be relative to the OPF file
          id: Utils.resolvePath(@id, path)
          mediaType: mediaType
          properties: $item.attr 'properties'

        allContent.add model
        @manifest.add model

        # If we stumbled upon the special navigation document
        # then remember it.
        if 'nav' == $item.attr('properties')
          @navModel = model

      # Ignore the spine because it is defined by the navTree in EPUB3.
      # **TODO:** Fall back on `toc.ncx` and then the `spine` to create a navTree if one does not exist
      return {title: title, bookId: bookId}

    getChildren: () -> @children
