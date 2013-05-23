define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.folder'
    branch: true
    expanded: false
    defaults:
      mediaType: 'application/vnd.org.cnx.folder'
      title: 'Untitled Folder'

    initialize: () ->
      @set('contents', new Backbone.Collection())

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @

    accepts: (mediaType) ->
      types = [
        'application/vnd.org.cnx.collection', # Book
        'application/vnd.org.cnx.module' # Module
      ]

      if (typeof mediaType is 'string')
        return _.indexOf(types, mediaType) is not -1

      return types
