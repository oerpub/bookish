define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.collection'
    branch: true
    defaults:
      manifest: null
      title: 'Untitled Book'
      contents: new Backbone.Collection()
