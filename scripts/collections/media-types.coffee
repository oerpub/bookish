# Extension point for handling various Media Types (Content)
# =======
#
# Several languages translate to HTML (Markdown, ASCIIDoc, cnxml).
#
# Developers can extend the types used by registering to handle different mime-types.
# Making an extension requires the following:
#
# - `parse()` and `serialize()` functions for
#     reading in the file and writing it to HTML
# - An Edit View for editing the content
#
# Entries in here contain a mapping from mime-type to an object that provides:
#
# - `.constructor` for instantiating a new `Backbone.Model` for this media type
# - `.editAction` which will change the page to become an edit page
# - `.accepts` hash of `mediaType -> addOperation` that is used for Drag-and-Dropping onto the content in the workspace list
#
# Different plugins (EPUB OPF, XHTML, Markdown, ASCIIDoc, cnxml) can add themselves to this
define [
  'underscore'
  'backbone'
  'cs!models/content/book'
  'cs!models/content/folder'
  'cs!models/content/module'
], (_, Backbone, Book, Folder, Module) ->

  # Collection used for storing the various mediaTypes.
  # When something registers a "New... mediaType" view can update
  return new (Backbone.Collection.extend
    # Just a glorified JSON holder (that cannot `sync`)
    model: Backbone.Model.extend
      sync: -> throw 'This model cannot be syncd'

    initialize: () ->
      @add Module
      @add Book
      @add Folder

    # Optionally pass in the `mediaType` so one model can handle multiple media types (like images)
    add: (modelType, options={}) ->
      mediaType = options.mediaType or modelType::mediaType
      Backbone.Collection::add.call(@, {id: mediaType, modelType: modelType}, options)

    type: (medium) ->
      model = Backbone.Collection::get.call(@, medium)

      if not model
        console.error "ERROR: No editor for media type '#{medium}'. Help out by writing one!"
        model = @models[0]

      return model.get('modelType')

    list: () ->
      return (type.get 'id' for type in @models)

    sync: -> throw 'This collection cannot be syncd'
  )()
