define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
], (_, Backbone, BaseContainerModel) ->

  class Book extends BaseContainerModel
    defaults:
      manifest: null
      title: 'Untitled Book'

    mediaType: 'application/vnd.org.cnx.collection'
    accept: ['application/vnd.org.cnx.module'] # Module
