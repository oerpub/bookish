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

    contentView: (callback) ->
      require ['cs!views/workspace/content/search-results'], (View) =>
        view = new View({collection: @get('contents')})
        callback(view)

    sidebarView: (callback) ->
      require ['cs!views/workspace/sidebar/toc'], (View) =>
        view = new View
          collection: @get('contents')
          model: @
        callback(view)
