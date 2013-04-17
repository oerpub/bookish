define [
  'exports'
  'underscore'
  'backbone'
  'bookish/media-types'
  'bookish/controller'
  'bookish/models'
  'bookish/views'
  'hbs!./opf-file'
  'hbs!./container-file'
  'hbs!./nav-serialize'
], (exports, _, Backbone, MEDIA_TYPES, Controller, Models, Views, OPF_TEMPLATE, CONTAINER_TEMPLATE, NAV_SERIALIZE) ->

  BaseCollection = Models.DeferrableCollection
  BaseContent = Models.BaseContent
  BaseBook = Models.BaseBook


  # Links in a navigation document are relative to where the nav document resides.
  # If it does not live in the same directory then they need to be resolved to
  # an absolute path so content Models can be looked up
  resolvePath = (context, relPath) ->
    return relPath if context.search('/') < 0
    context.replace(/\/[^\/]*$/, '') + '/' + relPath.split('#')[0]

  mixin = (src, dest) -> _.defaults dest, src


  TemplatedFileMixin =
    getterField: -> throw 'NO GETTER FIELD SET'
    template: -> throw 'NO TEMPLATE SET'

    parse: (xmlStr) ->
      # this method is called either:
      #
      # - when reading from a sync (`xmlStr` is a string of HTML)
      # - during construction (`xmlStr` is a dictionary of attributes)
      if 'string' == typeof xmlStr
        ret = {}
        ret[@getterField] = xmlStr
        return ret
      else
        return xmlStr
    serialize: -> @template @toJSON()

  HTMLFile = BaseContent.extend _.extend {}, TemplatedFileMixin, {
    mediaType: 'application/xhtml+xml'
    getterField: 'body'
    serialize: -> @get @getterField
  }

  PackageFileMixin = mixin TemplatedFileMixin,
    defaults: _.defaults(BaseBook.prototype.defaults,
      language: 'en'
      title: null
      creator: null
      created: null
      modified: null
      publisher: null
      copyrightDate: null
    )
    getterField: 'content'
    mediaType: 'application/vnd.org.cnx.collection'

    template: OPF_TEMPLATE
    manifestType: Backbone.Collection.extend
      # Serialize all the spine items
      toJSON: -> model.toJSON() for model in @models

    initialize: ->
      BaseBook.prototype.initialize.apply(@, arguments)

      # When the `navTreeStr` is changed on the package,
      # CHange it on the navigation.html file
      @listenTo @navTreeRoot, 'change:treeNode add:treeNode remove:treeNode', =>

        $newTree = jQuery(@navModel.get 'body')

        newTree = NAV_SERIALIZE @navTreeRoot.toJSON()
        $newTree = jQuery(newTree)

        $bodyNodes = jQuery(@navModel.get 'body')
        # wrap the elements in a div so we can call `$.find`
        $body = jQuery('<div></div>').append $bodyNodes

        $nav = $body.find('nav')
        if $nav
          $nav.replaceWith $newTree
        else
          $body.prepend $nav

        # Serialize the body back out to navigation.html

        if 'html' == $body[0].tagName.toLowerCase()
          bodyStr = $body[0].outerHTML
        else
          if $body.length != 1
            $wrap = jQuery('<div>/<div>')
            $wrap.append $body
            $body = $wrap
          # TODO: Add `<html><head>...</head>` tags around the `$body`
          bodyStr = $body[0].innerHTML

        # Set a `doNotReparse` option so when `change:body` is fired we do not
        # need to reparse the body and reset the ToC.
        @navModel.set 'body', bodyStr, {doNotReparse:true}


      # Once the OPF is populated load the navigation HTML file.
      # Change the model promise to wait for the navigation file to load
      # before considering the Book Loaded (daisy-chain the navigation file).
      @_promise = @loaded().then =>
        # Now we know what the navigation HTML file is so go pull it.
        # Then, this model is loaded and views can stop spinning and waiting

        @navModel.loaded().then =>
          # Finally, we have the Navigation HTML!

          # If its contents changes then so does the navTree
          @navModel.on 'change:body', (model, xmlStr, options) =>
            # Re-parse the tree and set it as the navTree
            # `parseNavTree` is defined in `AppModels.Book`
            @_updateNavTreeFromXML xmlStr if !options.doNotReparse

          # Give the HTML files in the manifest some titles from navigation.html
          navTree = @_updateNavTreeFromXML(@navModel.get('body'), {silent:true})
          recSetTitles = (nodes=[]) =>
            for node in nodes
              if node.id and node.id.search('#') < 0
                path = resolvePath(@navModel.id, node.id)
                model = Models.ALL_CONTENT.get path
                model.set {title: node.title}
                # Do not mark the object as 'dirty' (for saving)
                delete model.changed
              recSetTitles(node.children)
          recSetTitles navTree

          # Finally, this model is completely loaded.
          # Begin callbacks
          return @

    _updateNavTreeFromXML: (xmlStr, options) ->
      # Re-parse the tree and set it as the navTree
      # `parseNavTree` is defined in `AppModels.Book`

      $xml = jQuery(xmlStr)
      return @trigger 'error', 'Could not parse XML' if not $xml[0]

      # `$xml` may contain several top-level elements.
      # Wrap the `$xml` with a `<div/>` so we can call `$body.find()`
      $body = jQuery('<div></div>').append $xml

      # Find the tree and parse it into a JSON object
      $nav = $body.find 'nav'
      console.warn 'ERROR: Currently only 1 nav element in the navigation document is supported' if $nav.length != 1
      $nav = $nav.first()

      navTree = @parseNavTree($nav).children
      @navTreeRoot.reset navTree
      return navTree

    parse: (xmlStr) ->
      return xmlStr if 'string' != typeof xmlStr
      $xml = jQuery(jQuery.parseXML xmlStr)

      @manifest = new @manifestType if not @manifest

      # If we were unable to parse the XML then trigger an error
      return model.trigger 'error', 'INVALID_OPF' if not $xml[0]

      # For the structure of the TOC file see `OPF_TEMPLATE`
      bookId = $xml.find("##{$xml.get 'unique-identifier'}").text()

      title = $xml.find('title').text()

      # The manifest contains all the items in the spine
      # but the spine element says which order they are in

      $xml.find('package > manifest > item').each (i, item) =>
        $item = jQuery(item)

        # Add it to the set of all content and construct the correct model based on the mimetype
        mediaType = $item.attr 'media-type'
        path = $item.attr 'href'
        ContentType = MEDIA_TYPES.get(mediaType)
        model = new ContentType
          # Set the path to the file to be relative to the OPF file
          id: resolvePath(@id, path)
          properties: $item.attr 'properties'

        # if We could not find a suitable editor for the `mediaType` make sure
        # we do not lose that information when saving out the OPF file.
        model.mediaType = mediaType if !(mediaType in MEDIA_TYPES.list())

        Models.ALL_CONTENT.add model
        @manifest.add model

        # If we stumbled upon the special navigation document
        # then remember it.
        if 'nav' == $item.attr('properties')
          @navModel = model

      # Ignore the spine because it is defined by the navTree in EPUB3.
      # **TODO:** Fall back on `toc.ncx` and then the `spine` to create a navTree if one does not exist
      return {title: title, bookId: bookId}

    toJSON: ->
      json = BaseBook.prototype.toJSON.apply(@, arguments)
      json.manifest = @manifest?.toJSON()

      # Loop through everything in the manifest and add a `mediaType`
      _.each json.manifest, (item) ->
        item.mediaType = Models.ALL_CONTENT.get(item.id).mediaType

      json

    accepts: -> [ HTMLFile::mediaType, Models.Folder::mediaType ]


  PackageFile = BaseBook.extend PackageFileMixin




  EPUBContainer = BaseCollection.extend
    template: CONTAINER_TEMPLATE
    model: PackageFile
    defaults:
      urlRoot: ''
    url: -> 'META-INF/container.xml'

    toJSON: -> model.toJSON() for model in @models
    parse: (xmlStr) ->
      $xml = jQuery(xmlStr)
      ret = []
      $xml.find('rootfiles > rootfile').each (i, el) =>
        href = jQuery(el).attr 'full-path'
        ret.push {id: href}
      return ret


  # Add the `HTMLFile` and `PackageFile` to the media types registry.
  HTMLFile::editAction = -> Controller.editContent @
  PackageFile::editAction = -> Controller.editBook @
  Models.BookTocNode::accepts = -> [ Models.BookTocNode::mediaType, HTMLFile::mediaType ]

  MEDIA_TYPES.add HTMLFile
  MEDIA_TYPES.add PackageFile

  exports.EPUB_CONTAINER = new EPUBContainer()

  return exports
