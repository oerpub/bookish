define [
  'backbone'
  'cs!gh-book/xhtml-file'
  'cs!mixins/tree'
], (Backbone, XhtmlFile, treeMixin) ->

  mediaType = 'application/vnd.org.cnx.folder'

  class TocNode extends Backbone.Model

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      @set 'title', options.title
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, options) =>
        @trigger 'tree:change', model, @, options

      @initializeTreeHandlers(options)

    # Views rely on the mediaType to be set in here
    # TODO: Fix it in the view's `templateHelpers`
    toJSON: () ->
      json = super()
      json.mediaType = @mediaType
      return json


  # Add in the tree mixin
  return TocNode.extend treeMixin
