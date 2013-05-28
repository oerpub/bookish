define [
  'underscore'
  'backbone'
  'cs!models/content/base'
], (_, Backbone, BaseModel) ->

  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.folder'
    accept: [
      'application/vnd.org.cnx.collection', # Book
      'application/vnd.org.cnx.module' # Module
    ]
    branch: true
    expanded: false
    defaults:
      title: 'Untitled Folder'

    initialize: () ->
      @set('contents', new Backbone.Collection())

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @
