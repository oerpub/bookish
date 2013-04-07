# # Backbone Models
# This module contains backbone models used throughout the application
define ['exports', 'jquery', 'backbone', 'bookish/media-types', 'i18n!bookish/nls/strings'], (exports, jQuery, Backbone, MEDIA_TYPES, __) ->


  # Custom Models defined above are mixed in using `BaseContent.initialize`
  BaseContent = Backbone.Model.extend
    # New content is given an id before it is saved so it can be added to a book.
    # A book can refer to a new piece of content in its Table of Contents
    # (which could be stored in a HTML `<a href="[id]"/>` tag) so it needs some `id`.
    #
    # The Book Model can then listen to `change:id` and update the link when the
    # new content is saved and the id is updated.
    isNew: -> not @id or @id.match(/^_NEW:/)
    initialize: ->
      throw 'BUG: No mediaType set' if not @mediaType
      throw 'BUG: No mediaType not registered' if not MEDIA_TYPES.get @mediaType
      @id = "_NEW:#{@cid}" if not @id

  # ALL_CONTENT
  # =======
  # `ALL_CONTENT` stores all Content models known to the editor and provides a
  # way to look up any content by `id` if needed.
  #
  # It is also used by the **Save** button to decide if content has been changed.
  #
  # It is initially declared `null` because it is used by `DeferrableCollection`
  # and instantiated afterwards (cyclic dependency)
  ALL_CONTENT = null

  # Fully loading Content
  # =======
  # A model representing a piece of content may have been instantiated
  # (ie an entry as a result of a search) but not fetched yet.
  #
  # When dealing with a model (except for `id`, `title`, or `mediaType`)
  # be sure to call `.loaded().done(cb).fail(cb)` first.
  #
  # Once the model is loaded (fetched) call the callbacks.

  Deferrable = Backbone.Model.extend
    # Returns a promise that the piece of content will be fully populated from
    # the server.
    # Initially the content is partially populated from a Search result, folder
    # listing, or some other method that allowed the user to 'click' on to begin
    # viewing/editing the full piece of content.
    #
    # **FIXME:** If `@isNew()` then the Model should always be fully loaded.
    loaded: (flag=false) ->
      if flag # or @isNew()
        deferred = jQuery.Deferred()
        deferred.resolve @
        @_promise = deferred.promise()
        # Mark it as loaded for the views.
        # By setting an attribute views can listen to a change and rerender,
        # replacing the progress bar with the actual view
        @set {_done: true}

      # Silently update the model (the user has not seen the model yet)
      # so `model.hasChanged()` returns `false` (to know when to enable Saving)
      if not @_promise or 'rejected' == @_promise.state()
        @set {_loading: true}
        # **TODO:** Set `silent:true` during the fetch (So save doesn't trigger)
        # but make sure all the views listen to `change:_done` so they always update
        # instead of relying on `change:*`.
        @_promise = @fetch # {silent:true}
          error: (model, message, options) =>
            @trigger 'error', model, message, options
        @_promise
        .progress (progress) =>
          @set {_progress: progress}
        .done =>
          # Once we are done fetching and the change events have fired
          # clear all the `.changed` flag so save does not think it has dirty models
          delete @changed
          @set {_done: true}
        .fail (error) =>
          @trigger 'error', error

      return @_promise

    # Add the `mediaType` to the JSON
    toJSON: ->
      json = Backbone.Model.prototype.toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      return json

  # Collection analog of `Deferrable`
  DeferrableCollection = Backbone.Collection.extend

    # This is mostly the same code in `Deferrable.loaded`.
    loaded: (flag) ->
      if flag
        deferred = jQuery.Deferred()
        deferred.resolve @
        @_promise = deferred.promise()
        # Mark it as loaded for the views
        @_done = true

      # Silently update the model (the user has not seen the model yet)
      # so `model.hasChanged()` returns `false` (to know when to enable Saving)
      if not @_promise or 'rejected' == @_promise.state()
        # **TODO:** Match the "Set `silent:true` " TODO in `Deferrable`
        @_promise = @fetch # {silent:true}
          error: (model, message, options) =>
            @trigger 'error', model, message, options

        # Once we are done fetching and the change events have fired
        # clear all the `.changed` flag so save does not think it has dirty models
        @_promise.then => delete @changed

      return @_promise

    toJSON: -> (model.toJSON() for model in @models)
    initialize: ->
      # When a collection is updated make sure `ALL_CONTENT` has a reference to all
      # the added models.
      @on 'add',   (model) -> ALL_CONTENT.add model
      @on 'reset', (collection, options) -> ALL_CONTENT.add collection.toArray()


  # All Content
  # =======
  #
  # To prevent multiple copies of a model from floating around a single
  # copy of all referenced content (loaded or not) is kept in this Collection
  #
  # This should be read-only by others
  # New content models should be created by calling `ALL_CONTENT.add {}`
  AllContent = DeferrableCollection.extend
    model: BaseContent
    # Override the `DeferrableCollection` initialize because this is the `ALL_CONTENT`
    initialize: ->
      # Never wait to fetch this collection
      @loaded(true)

  ALL_CONTENT = new AllContent()


  # When searching for text, perform a local filter on content while the search
  # waits for the server to respond.
  #
  # This Collection takes another Collection and maintains an active filter on it.
  #
  # **FIXME:** Move the `exports.` part down to the bottom of this file.
  exports.FilteredCollection = Backbone.Collection.extend
    defaults:
      collection: null

    setFilter: (str) ->
      return if @filterStr == str
      @filterStr = str

      # Remove anything that no longer matches
      models = (@collection.filter (model) => @isMatch(model))
      @reset models

    isMatch: (model) ->
      return true if not @filterStr
      # Search inside the `title` attribute first.
      title = model.get('title') or ''
      found = title.toLowerCase().search(@filterStr.toLowerCase()) >= 0
      return true if found

      # Search inside the `body` attribute if it exists,
      # filtering out HTML tag names and attributes.
      body = model.get('body') or ''
      bodyText = body.replace(/\<(\/?[^\\>]+)\\>/, ' ').replace(/\s+/, ' ').trim()

      # **FIXME:** Whoops! Add code to actually search the `body`

    initialize: (models, options) ->
      @filterStr = options.filterStr or ''
      @collection = options.collection
      throw 'BUG: Cannot filter on a non-existent collection' if not @collection

      # Initially add all models that match the current filter
      @add (@collection.filter (model) => @isMatch(model))

      # Update the filtered collection when items are added/removed
      @listenTo @collection, 'add',    (model) => @add model if @isMatch(model)
      @listenTo @collection, 'remove', (model) => @remove model
      @listenTo @collection, 'reset',  (model, options) =>
        @reset()
        @add (@collection.filter (model) => @isMatch(model))

      # If the model changes and the filter now does/does-not apply then update
      @listenTo @collection, 'change', (model) =>
        if @isMatch(model)
          @add model
        else
          @remove model



  # The `Content` model contains the following members:
  #
  # * `title` - an HTML title of the content
  # * `language` - the main language (eg `en-us`)
  # * `subjects` - an array of strings (eg `['Mathematics', 'Business']`)
  # * `keywords` - an array of keywords (eg `['constant', 'boltzmann constant']`)
  # * `authors` - an `Collection` of `User`s that are attributed as authors
  BaseContent = Deferrable.extend
    mediaType: 'application/vnd.org.cnx.module'
    defaults:
      title: null
      subjects: []
      keywords: []
      authors: []
      copyrightHolders: []
      # Default language for new content is the browser's language
      language: (navigator?.userLanguage or navigator?.language or 'en').toLowerCase()

  # Used below to create JSON representation of model
  Backbone_Model_toJSON = Backbone.Model::toJSON

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

  # Represents an item in the ToC
  BookTocNode = Backbone.Model.extend
    # Recursively include child nodes in the returned JSON
    toJSON: ->
      json = Backbone_Model_toJSON.apply(@)
      json.children = @children.toJSON() if @children.length
      json

    # Return the `id` of the corresponding Content Model represented by this node.
    # This is used to "look up" the original title of content if it has not been
    # Overridden in the book.
    contentId: -> @id

    initialize: ->
      @on 'change', => @trigger 'change:treeNode'

      # If the Tree Node is initialized with a `children` property
      # then use that config to recursively create new child nodes.
      children = @get 'children'
      @unset 'children', {silent:true}

      @children = new BookTocNodeCollection()

      @children.on 'add', (child, collection, options) =>
        child.parent = @
        @trigger 'add:treeNode', child, @, options
      @children.on 'remove', (child, collection, options) =>
        delete child.parent
        @trigger 'remove:treeNode', child, @, options

      @children.add children
      @children.each (child) => child.parent = @


  BookTocNodeCollection = Backbone.Collection.extend
    model: BookTocNode


  # Root of a Tree
  # -------
  # Events that "bubble up" the tree can be listened to on this object
  #
  # Additionally, it contains a `Backbone.Collection` of `descendants` which
  # contains all nodes in the tree (That's how the events "bubble up").
  #
  # The Model can be thought of as a `<ul>` since it does not contain
  # any interesting fields itself except for `children`.
  BookTocTree = BookTocNode.extend
    toJSON: -> @children.toJSON()

    initialize: ->
      BookTocNode::initialize.call(@)
      @descendants = new BookTocNodeCollection()

      # Populate the descendants collection
      recDescendants = (node) =>
        @descendants.add node
        node.children.each (child) -> recDescendants(child)

      @children.each (child) -> recDescendants(child)

      # These events are created when someone adds to `BookTocNode.children`
      # And fired from the `BookTocNode`
      @descendants.on 'add:treeNode', (node) =>
        @descendants.add node
        @trigger 'add:treeNode', node
      # **TODO:** I think this one does not work because the node is removed
      # from the collection before the event bubbles up so it does not bubble up
      @descendants.on 'remove:treeNode', (node) =>
        @descendants.remove node
        @trigger 'remove:treeNode', node

      @descendants.on 'change:treeNode', (node) =>
        @trigger 'change:treeNode', node

    # When the whole tree needs to be reset call this.
    reset: (nodes) ->
      @descendants.reset()
      @children.reset nodes
      # recursively add nodes to the descendants
      recAddDescendants = (node) =>
        @descendants.add node
        node.children.each (child) => recAddDescendants child

      @children.each (child) => child.parent = @; recAddDescendants child


  # BaseBook (Connexions Collection)
  # =======
  # Represents a "collection" in [Connexions](http://cnx.org) terminology and an `.opf` file in an EPUB
  BaseBook = Deferrable.extend
    mediaType: 'application/vnd.org.cnx.collection'
    defaults:
      manifest: null

    # Subclasses can provide a better Collection for storing Content items in a book
    # so the book can listen to changes.
    manifestType: Backbone.Collection

    # **FIXME:** Adding the `navTreeRoot` should probably be removed since the views are recursive
    # and never need the entire JSON
    toJSON: ->
      json = Deferrable.prototype.toJSON.apply(@, arguments)
      json.navTree = @navTreeRoot.toJSON()
      return json

    # Takes an element representing a `<nav epub:type="toc"/>` element
    # and returns a JSON tree with the following structure:
    #
    #     [
    #       {id: 'path/to/file1.html', title: 'Appendix', children: [...] },
    #       {title: 'Unit 3', class: 'unit', children: [...] }
    #     ]
    # See [The toc nav Element](http://idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-nav-def-types-toc) for more information.
    #
    # This method is also used by the DnD edit view.
    #
    # Example from an ePUB3:
    #
    #     <nav epub:type="toc">
    #       <ol>
    #         <li><a href="path/to/file1.html">Appendix</a></li>
    #         <li class="unit"><span>Unit 3</span><ol>[...]</ol></li>
    #       </ol>
    #     </nav>
    #
    # Example from the Drag-and-Drop Book editor (Tree View):
    #
    #     <div>
    #       <ol>
    #         <li><span data-id="path/to/file1.html">Appendix</a></li>
    #         <li class="unit"><span>Unit 3</span><ol>[...]</ol></li>
    #       </ol>
    #     </nav>
    parseNavTree: (li) ->
      $li = jQuery(li)

      $a = $li.children 'a, span'
      $ol = $li.children 'ol'

      obj = {id: $a.attr('href') or $a.data('id')}

      # Don't set the title if we have not overridden it
      obj.title = $a.text() if !$a.hasClass 'autogenerated-text'

      # The custom class is either set on the `$span` (if parsing from the editor) or on the `$a` (if parsing from an EPUB)
      obj.class = $a.data('class') or $a.not('span').attr('class')

      obj.children = (@parseNavTree(li) for li in $ol.children()) if $ol[0]
      return obj

    # Creates a Manifest collection of all content it should listen to.
    #
    # For example, changes to `id` or `title` of a piece of content will update the navigation tree.
    #
    # Similarly, an update to the navigation tree will create new models.
    initialize: ->

      @manifest = new @manifestType()
      @navTreeRoot = new BookTocTree()

      @listenTo @manifest, 'add',   (model, collection) -> ALL_CONTENT.add model
      @listenTo @manifest, 'reset', (model, collection) -> ALL_CONTENT.add model

      # If a model's id changes then update the `navTree` (it was a new model that got saved)
      @listenTo @manifest, 'change:id', (model, newValue, oldValue) =>
        node = @navTreeRoot.descendants.get oldValue
        return console.error 'BUG: There is an entry in the tree but no corresponding model in the manifest' if not node
        node.set('id', newValue)

      # If a piece of content is linked to in the navigation document
      # always include it in the manifest
      @listenTo @navTreeRoot, 'add:treeNode', (navNode) => @manifest.add ALL_CONTENT.get(navNode.contentId())
      @listenTo @navTreeRoot, 'remove:treeNode', (navNode) => @manifest.remove ALL_CONTENT.get(navNode.contentId())

      # Trigger a change so `save` works
      @listenTo @navTreeRoot, 'add:treeNode',    (navNode) => @trigger 'add:treeNode', @
      @listenTo @navTreeRoot, 'remove:treeNode', (navNode) => @trigger 'remove:treeNode', @
      @listenTo @navTreeRoot, 'change:treeNode', (navNode) =>
        @trigger 'change:treeNode', @
        @trigger 'change', @

      # Do this last so `.toJSON()` has the `navTreeRoot` already initialized
      ALL_CONTENT.add @


    # Used by `MEDIA_TYPES.get(...).accepts` to add new content when content
    # is dropped on the book in the Workspace/Search Results views.
    #
    # Convenience method for `.navTreeRoot.children.add {id: model.get('id')}, {at: 0}`
    #
    # **FIXME:** Somewhat hacky way of creating a new piece of content (remove the `mediaType` arg)
    prependNewContent: (model, mediaType) ->
      if model instanceof Backbone.Model
        # If the model is already in the book then do not add it again
        return if @manifest.get model.id

        @manifest.add model

      else if mediaType
        config = model
        throw 'BUG: Media type not registered' if not MEDIA_TYPES.get mediaType

        # Create the model from a config and add it to the manifest
        ContentType = MEDIA_TYPES.get(mediaType).constructor
        model = new ContentType config
        # Mark it as sync'd so we don't try to fetch a non-existent file
        # **FIXME:** Have `Deferred.loaded()` use `Model.isNew()` to decide if the Model is fully loaded.
        model.loaded(true)

        @manifest.add model
        console.warn 'FIXME: Hack for new content'

      else
        # Otherwise, just add a container
        model = new Backbone.Model model

      # Prepend to the navTree
      @navTreeRoot.children.add {id: model.get('id')}, {at: 0}


  # Compare by `mediaType` (Collections/Books 1st), then by title/URL
  CONTENT_COMPARATOR = (a, b) ->
    A = a.mediaType or ''
    B = b.mediaType or ''
    return -1 if B < A
    return 1  if A < B

    A = a.get('title') or a.id or ''
    B = b.get('title') or b.id or ''
    return 1 if B < A
    return -1  if A < B

    return 0

  # Add the 2 basic Media Types already defined above.
  #
  # **FIXME:** Move these into the `controller` file instead of here.
  #
  # **FIXME:** Move the `application/xhtml+xml` into the `epub/` code.
  MEDIA_TYPES.add 'application/vnd.org.cnx.module',
    constructor: BaseContent

  MEDIA_TYPES.add 'application/vnd.org.cnx.collection',
    constructor: BaseBook
    accepts:
      'application/xhtml+xml': (book, model) ->
        book.prependNewContent model
      'application/vnd.org.cnx.module': (book, model) ->
        book.prependNewContent model

  # Finally, export only the pieces needed
  exports.BaseContent = BaseContent
  exports.BaseBook = BaseBook
  exports.BookTocTree = BookTocTree
  exports.Deferrable = Deferrable
  exports.DeferrableCollection = DeferrableCollection
  exports.ALL_CONTENT = ALL_CONTENT
  # **FIXME:** Remove the next line
  exports.MEDIA_TYPES = MEDIA_TYPES
  exports.CONTENT_COMPARATOR = CONTENT_COMPARATOR
  # Other implementations can override this
  exports.WORKSPACE = ALL_CONTENT
  return exports
