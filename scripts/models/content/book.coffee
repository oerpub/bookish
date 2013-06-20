define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
], (_, Backbone, BaseContainerModel) ->

  return BaseContainerModel.extend
    defaults:
      manifest: null
      title: 'Untitled Book'

    mediaType: 'application/vnd.org.cnx.collection'
    accept: ['application/vnd.org.cnx.module'] # Module
