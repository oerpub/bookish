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
    branch: true
    expanded: false

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
