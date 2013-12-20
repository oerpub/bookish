define [
  'backbone'
  'cs!models/content/inherits/saveable'
  'cs!mixins/tree'
  'cs!models/content/book'
  'cs!models/content/module'
  'cs!models/content/folder'
  'cs!collections/content'
  'filtered-collection'
], (Backbone, Saveable, treeMixin, Book, Module, Folder, allContent) ->

  return new class WorkspaceRoot extends Saveable.extend(treeMixin)
    accept: [Book::mediaType, Module::mediaType, Folder::mediaType]
    initialize: (options) ->
      super(options)

      content = new Backbone.FilteredCollection(null, {collection:allContent})

      # Allow `.add` to be called on filtered collections (for new Books)
      content.add = allContent.add.bind(allContent)

      # Filter the Workspace sidebar to only contain Book and Folder
      content.setFilter (model) => return model.mediaType in [Book::mediaType, Folder::mediaType]

      @_initializeTreeHandlers {root:@, children:content}

    # Just return the node; for a Book this would return options.model wrapped in a TocPointerNode
    newNode: (options) ->
      return options.model
