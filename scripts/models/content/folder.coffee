define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
], (_, Backbone, BaseContainerModel) ->

  return BaseContainerModel.extend
    mediaType: 'application/vnd.org.cnx.folder'
    accept: [
      'application/vnd.org.cnx.collection', # Book
      'application/vnd.org.cnx.module' # Module
    ]
    branch: true
    expanded: false
    defaults:
      title: 'Untitled Folder'
