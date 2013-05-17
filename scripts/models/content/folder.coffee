define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    defaults:
      title: 'Untitled Folder'
    mediaType: 'application/vnd.org.cnx.folder'
    initialize: ->
      @contents = new Backbone.Collection()
    #accepts: -> [ BaseBook::mediaType, BaseContent::mediaType ]
