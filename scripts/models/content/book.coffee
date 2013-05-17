define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.collection'
    defaults:
      manifest: null
      title: 'Untitled Book'
