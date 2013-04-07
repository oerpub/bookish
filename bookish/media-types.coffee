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
define ['backbone'], (Backbone) ->

  # Collection used for storing the various mediaTypes.
  # When something registers a "New... mediaType" view can update
  MediaTypes = Backbone.Collection.extend
    # Just a glorified JSON holder (that cannot `sync`)
    model: Backbone.Model.extend
      sync: -> throw 'This model cannot be syncd'
    sync: -> throw 'This model cannot be syncd'

  # Singleton collection
  MEDIA_TYPES = new MediaTypes()

  return {
    add: (mediaType, config) ->
      prev = MEDIA_TYPES.get(mediaType)
      throw 'BUG: You must at least specify a constructor!' if not config.constructor and not prev

      # Before calling the accept method make sure the long-form of the content
      # is loaded. (`mt` is `mediaType`)
      for mt, func of config.accepts or {}
        config.accepts[mt] = (me, droppedContent) ->
          me.loaded().done ->
            func(me, droppedContent)

      MEDIA_TYPES.add _.extend(config, {id: mediaType}), {merge:true}

    get: (mediaType) ->
      type = MEDIA_TYPES.get mediaType
      if not type
        console.error "ERROR: No editor for media type '#{mediaType}'. Help out by writing one!"
        return MEDIA_TYPES.models[0]
        #     throw 'BUG: mediaType not found'
      return _.omit(type.toJSON(), 'id')

    # Provides a list of all registered media types
    list: ->
      return (type.get 'id' for type in MEDIA_TYPES.models)

    # So views can listen to changes
    asCollection: ->
      return MEDIA_TYPES
  }
