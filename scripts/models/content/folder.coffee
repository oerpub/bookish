define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
], (_, Backbone, BaseContainerModel) ->

  return BaseContainerModel.extend
    defaults:
      title: 'Untitled Folder'

    mediaType: 'application/vnd.org.cnx.folder'
    accept: [
      'application/vnd.org.cnx.collection', # Book
      'application/vnd.org.cnx.module' # Module
    ]