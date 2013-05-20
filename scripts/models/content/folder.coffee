define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.folder'
    branch: true
    defaults:
      title: 'Untitled Folder'
      contents: new Backbone.Collection()

    #accepts: -> [ BaseBook::mediaType, BaseContent::mediaType ]
