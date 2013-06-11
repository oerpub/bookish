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

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @

    contentView: (callback) ->
      #require ['cs!views/content'], (view) ->
      #  callback(view)

    sidebarView: (callback) ->
      require ['cs!views/workspace/sidebar/toc'], (View) =>
        view = new View({collection: @get('contents')})
        callback(view)
