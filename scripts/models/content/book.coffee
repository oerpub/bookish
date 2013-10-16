define [
  'underscore'
  'backbone'
  'cs!collections/content'
  'cs!models/content/module'
  'cs!mixins/loadable'
  'cs!models/content/book-toc-node'
  'cs!models/content/toc-pointer-node'
  'cs!models/utils'
], (_, Backbone, allContent, Module, loadable, TocNode, TocPointerNode, Utils) ->

  return class BookModel extends (TocNode.extend loadable)
    mediaType: 'application/vnd.org.cnx.collection'
    accept: [Module::mediaType, TocNode::mediaType]

    # Used to fetch/save the content.
    # TODO: move the URL pattern to a separate file so it is configurable
    url: () ->
      if @id
        return "/content/#{@id}"
      else
        return '/content/'

    initialize: (options) ->

      # For TocNode, let it know this is the root
      super {root:@}

      # TODO: Refactor references to @navModel
      # Used by gh-book because the OPF and navigation document are separate
      @navModel = @

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

      @tocNodes.on 'add', (model, collection, options) =>
        if not options.doNotReparse
          # Keep track of local changes if there is a remote conflict
          @_localNavAdded[model.id] = model

      # If a node was added-to/removed-from a TocNode ensure it is/is-not in the set of `tocNodes`
      # TODO: This may be redundant and may be able to be removed
      @tocNodes.on 'tree:add',    (model, collection, options) => @tocNodes.add model, options
      @tocNodes.on 'tree:remove', (model, collection, options) => @tocNodes.remove model, options

      # When a title changes on one of the nodes in the ToC:
      #
      # 1. remember the change
      # 2. try to autosave
      # 3. if a remote conflict occurse the remembered change will be replayed (see `onReloaded`)
      @tocNodes.on 'change:title', (model, value, options) =>
        return if not model.previousAttributes()['title'] # skip if we are parsing the file
        return if @ == model # Ignore if changing the OPF title
        # the `change:title` event "trickles up" through the nodes (probably should not)
        # so only save once.
        if @_localTitlesChanged[model.id] != value
          @_localTitlesChanged[model.id] = value
          @_save()

      @tocNodes.on 'add remove tree:change', (model, collection, options) =>
        setNavModel(options)
      @tocNodes.on 'change reset', (collection, options) =>
        setNavModel(options)

      # These store the added items since last successful save.
      # If this file was remotely updated then, when resolving conflicts,
      # these items will be added back into the newly-updated OPF manifest
      @_localNavAdded = {}
      @_localTitlesChanged = {}


    _loadComplex: (fetchPromise) ->
      # OPF subclass will add an event listener on `@navModel.on 'change:body', ...`
      # but since the navModel is @ we can jsut listen now
      # TODO: This could also be implemented in the constructor as `@navModel?.on ...`
      @on 'change:body', (model, value, options) =>
        return if options.parse or options.doNotReparse
        @_parseNavModel(@get('body'))
      return fetchPromise

    # This specifies the mediaType of new Toc entries that do not exist in allContent yet.
    # It is used when the GitHub book Navigation file is updated before the OPF file is.
    # It is unused by `atc`.
    # Used in `_parseNavModel`.
    newModelMediaType: Module::mediaType
    # This method is given a Toc entry and the title in the Toc.
    # Optionally, the method can assign the title to the Toc entry.
    # It is unused by `atc`.
    # Used in `_parseNavModel`.
    onParseNavEntry: (model, title) -> # no-op


    parse: (json) ->
      body = json.body
      # Remove the body since we parse it manually
      json = _.omit('body')
      @_parseNavModel(body)
      return json


    _parseNavModel: (bodyHtml) ->
      $body = $(bodyHtml)
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
            href = $a.attr('href')
            title = null
            title = $a.text() if not $a.hasClass('autogenerated-text')

            path = Utils.resolvePath(contextPath, href)
            contentModel = allContent.get(path)
            # Because of remotely adding a new file and reloading files async
            # it may be the case that the navigation document
            # (containing a link to the new XhtmlFile)
            # reloads before the OPF file reloads (containing the <item> which updates allContent)
            # so we cannot assume the model is already in `allContent`
            #
            # In that case, just add a "shallow" model to allContent
            if not contentModel
              contentModel = allContent.model
                mediaType: @newModelMediaType
                id: path
              allContent.add(contentModel)

            @onParseNavEntry(contentModel, title)

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
      $nav = $wrapper.find('nav')
      # If <nav> does not exist then add a new one
      if not $nav[0]
        $nav = $('<nav></nav>')
        $wrapper.append($nav)
      $nav.empty()

      $navOl = $('<ol></ol>')

      recBuildList = ($rootOl, model) =>
        $li = $('<li></li>')
        $rootOl.append $li

        if model.dereferencePointer
          path = Utils.relativePath(@navModel.id, model.id)
          $node = $('<a></a>')
          .attr('href', path)
        else
          $node = $('<span></span>')
          $li.attr(model.htmlAttributes or {})

        title = model.get('title')
        # If it is an overridden title then set it.
        # Otherwise add some autogenerated text and a class marking that it is autogenerated
        if title
          $node.html(title)
        else
          $node.addClass('autogenerated-text')
          $node.html('AUTOGENERATED_TITLE')

        $li.append $node

        if model.getChildren?().first()
          $ol = $('<ol></ol>')
          # recursively add children
          model.getChildren().forEach (child) => recBuildList($ol, child)
          $li.append $ol

      @getChildren().forEach (child) => recBuildList($navOl, child)
      $nav.append($navOl)
      # Trim the HTML and put newlines between elements
      html =  $wrapper.html()
      html = html.replace(/></g, '>\n<')
      return html


    # Resolves conflicts between changes to this model and the remotely-changed
    # new attributes on this model.
    onReloaded: () ->
      @_parseNavModel(@get('body'))
      _.each @_localNavAdded, (model, path) => @addChild(model)

      isDirty = not _.isEmpty(@_localNavAdded)

      # Merge in the local title changes for items still in the ToC
      _.each @_localTitlesChanged, (title, id) =>
        model = @tocNodes.get(id)
        model?.set('title', title, {parse:true})

      isDirty = isDirty or not _.isEmpty(@_localTitlesChanged)

      return isDirty

    onSaved: () ->
      @_localNavAdded = {}
      @_localTitlesChanged = {}


    newNode: (options) ->
      model = options.model
      node = @tocNodes.get model.id
      if not node
        node = new TocPointerNode {root:@, model:model, title:options.title}
        #@tocNodes.add node
      return node

    _save: () -> console.log "ERROR: Autosave not implemented"

    # Do not change the contentView when the book opens
    contentView: null

    # Change the sidebar view when editing this
    sidebarView: (callback) ->
      require ['cs!views/workspace/sidebar/toc'], (View) =>
        view = new View
          collection: @getChildren()
          model: @
        callback(view)
