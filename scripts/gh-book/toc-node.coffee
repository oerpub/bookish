define [
  'backbone'
  'cs!gh-book/xhtml-file'
  'cs!models/content/inherits/saveable'
  'cs!mixins/tree'
], (Backbone, XhtmlFile, SaveableModel, treeMixin) ->

  mediaType = 'application/vnd.org.cnx.section'

  class TocNode extends SaveableModel # Extend SaveableModel so you can get the isDirty for saving

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      super(options)
      @set 'title', options.title
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, value, options) =>
        @trigger 'tree:change', model, @, options

      @_initializeTreeHandlers(options)

    # Views rely on the mediaType to be set in here
    # TODO: Fix it in the view's `templateHelpers`
    toJSON: () ->
      json = super()
      json.mediaType = @mediaType
      return json


  # Add in the tree mixin
  return TocNode.extend treeMixin
