define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    url: () -> return "/api/contents/#{ @id }"
    mediaType: 'application/vnd.org.cnx.module'

    toJSON: () ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      json.id = @id or @cid

      return json
