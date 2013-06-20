define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return Backbone.Model.extend
    url: () -> return "/api/content/#{ @id }"
    mediaType: 'application/vnd.org.cnx.module'

    toJSON: () ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType

      return json

    getTitle: (container) ->
      if @unique
        title = @get('title')
      else
        title = container?.getTitle?(@) or @get('title')

      return title

    setTitle: (container, title) ->
      if @unique
        @set('title', title)
      else
        container?.setTitle?(@, title) or @set('title', title)
