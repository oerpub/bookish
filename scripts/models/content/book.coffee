define [
  'underscore'
  'backbone'
  'cs!models/content/base'
], (_, Backbone, BaseModel) ->

  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.collection'
    accept: ['application/vnd.org.cnx.module'] # Module
    branch: true
    expanded: false
    defaults:
      manifest: null
      title: 'Untitled Book'

    initialize: () ->
      @set('contents', new Backbone.Collection())

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @

    contentView: (callback) ->
      #require ['cs!views/content'], (view) ->
      #  callback(view)

    sidebarView: (callback) ->
      require ['cs!views/workspace/toc'], (View) =>
        view = new View({collection: @get('contents')})
        callback(view)
