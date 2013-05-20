define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.folder'
    branch: true
    defaults:
      mediaType: 'application/vnd.org.cnx.folder'
      title: 'Untitled Folder'
      contents: new Backbone.Collection()

    #accepts: -> [ BaseBook::mediaType, BaseContent::mediaType ]
