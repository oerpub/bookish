define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.collection'
    branch: true
    defaults:
      manifest: null
      title: 'Untitled Book'
      mediaType: 'application/vnd.org.cnx.collection'

    initialize: () ->
      @set('contents', new Backbone.Collection())

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @

    accepts: (mediaType) ->
      types = ['application/vnd.org.cnx.module'] # Module

      if (typeof mediaType is 'string')
        return _.indexOf(types, mediaType) is not -1

      return types
