define [
  'underscore'
  'backbone'
  'cs!collections/content'
  'cs!models/content/module'
  'cs!mixins/tree'
  'cs!mixins/loadable'
  'cs!models/content/inherits/saveable'
  'cs!models/content/book-toc-node'
  'cs!models/content/toc-pointer-node'
  'cs!models/utils'
], (_, Backbone, allContent, Module, treeMixin, loadable, SaveableModel, TocNode, TocPointerNode, Utils) ->

  # Mixin the tree before so TocNode can override `addChild`
  SaveableTree = SaveableModel.extend(treeMixin).extend(loadable)

  return class FolderModel extends SaveableTree # Extend SaveableModel so you can get the isDirty for saving
    mediaType: 'application/vnd.org.cnx.folder'
    accept: [
      'application/vnd.org.cnx.collection', # Book
      'application/vnd.org.cnx.module' # Module
    ]

    # Used to fetch/save the content.
    # TODO: move the URL pattern to a separate file so it is configurable
    # TODO: This is copy/pasta from BookModel; remove it
    url: () ->
      if @id
        return "/content/#{@id}"
      else
        return '/content/'

    initialize: (options) ->

      # For TocNode, let it know this is the root
      super {root:@}
      @_initializeTreeHandlers {root:@}

      # Mark this as dirty when the contents of the Folder changes
      @getChildren().on 'add remove', (collection, model, options) =>
        @_markDirty(options, true) # force == true

      @getChildren().on 'reset', (collection, options) =>
        @_markDirty(options)

      @on 'change:title', (model, value, options) =>
        @_markDirty(options)

      # These store the added items since last successful save.
      # If this file was remotely updated then, when resolving conflicts,
      # these items will be added back into the newly-updated OPF manifest
      @_localContentsAdded = {}


    parse: (json) ->
      children = json.contents.map (id) =>
        model = allContent.get(id)
        throw new Error 'BUG: id not found when loading folder' if not model
        return @newNode {model:model}
      @getChildren().reset(children, {parse:true})

      delete json.contents
      return json


    # Resolves conflicts between changes to this model and the remotely-changed
    # new attributes on this model.
    onReloaded: () ->
      _.each @_localContentsAdded, (model, path) => @addChild(model)

      isDirty = not _.isEmpty(@_localContentsAdded)
      return isDirty

    onSaved: () ->
      super()
      @_localContentsAdded = {}

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

    # The structure of Folder requires that it look something like:
    #
    #     {..., contents: ['id1', 'id2']}
    #
    # For Sidebar rendering those child models are in `@getChildren()`.
    # Pull them out and generate the simple array shown above.
    toJSON: () ->
      json = super()

      json.contents = @getChildren().map (child) =>
        console.warn 'TODO: adding new content to a folder is not supported yet' if child.isNew()
        return child.id

      return json

    newNode: (options) ->
      model = options.model
      node = new TocPointerNode {root:@, model:model, passThroughChanges:true}
      return node
