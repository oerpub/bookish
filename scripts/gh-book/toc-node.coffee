define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
  'cs!gh-book/xhtml-file'
], (_, Backbone, BaseContainerModel, XhtmlFile) ->

  mediaType = 'application/vnd.org.cnx.folder'

  class TocNode extends BaseContainerModel
    defaults:
      title: 'Untitled Section'

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      throw 'BUG: Missing constructor options' if not options
      throw 'BUG: Missing title' if not options.title

      @children = new Backbone.Collection()
      @set 'title', options.title
      #@attributes = options.attributes or {}

      @on 'change:title', () ->
        console.log "TItle changed to #{@get 'title'}"

    getChildren: () -> @children
