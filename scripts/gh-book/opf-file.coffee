define [
  'jquery'
  'underscore'
  'backbone'
  'cs!collections/media-types'
  'cs!collections/content'
  'cs!models/content/inherits/container'
  'cs!gh-book/utils'
], ($, _, Backbone, mediaTypes, allContent, BaseContainerModel, Utils) ->

  return class PackageFile extends BaseContainerModel
    defaults:
      manifest: null
      title: 'Untitled Book'

    mediaType: 'application/oebps-package+xml'
    accept: ['text/html', 'application/xhtml+xml'] # Module


    initialize: () ->
      @manifest = new Backbone.Collection()
      @load()
    load: () ->
      @fetch
        success: () =>
          @navModel.fetch
            success: () =>
              @parseNavModel()

    # Update the titles of all Xhtml Models
    parseNavModel: () ->
      $body = $(@navModel.get 'body')
      $links = $body.find 'a[href]'
      $links.each (i, el) =>
        $link = $(el)
        href = $link.attr 'href'
        id = Utils.resolvePath @navModel.id, href
        title = $link.text()

        model = allContent.get id
        model.set 'title', title

        @listenTo model, 'change:title', () =>
          console.warn 'TODO: BUG: Change the title in the ToC'

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

