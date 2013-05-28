define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.module'
    accept: []

    accepts: (mediaType) ->
      if (typeof mediaType is 'string')
        return _.indexOf(@accept, mediaType) is not -1

      return @accept

    toJSON: () ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      json.id = @id or @cid

      return json
