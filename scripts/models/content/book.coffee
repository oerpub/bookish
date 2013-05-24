define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.collection'
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

    accepts: (mediaType) ->
      types = ['application/vnd.org.cnx.module'] # Module

      if (typeof mediaType is 'string')
        return _.indexOf(types, mediaType) is not -1

      return types

    toJSON: () ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      json.id = @cid

      return json
