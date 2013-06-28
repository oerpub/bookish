define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
  'cs!gh-book/xhtml-file'
], (_, Backbone, BaseContainerModel, XhtmlFile) ->

  mediaType = 'application/vnd.org.cnx.folder'

  return class TocNode extends BaseContainerModel
    defaults:
      title: 'Untitled Section'

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      @children = new Backbone.Collection()
      @set 'title', options.title

    getChildren: () -> @children
