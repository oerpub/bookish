define [
  'jquery'
  'underscore'
  'backbone'
  'cs!mixins/loadable'
], ($, _, Backbone, loadable) ->

  class BaseModel extends Backbone.Model
    url: () -> return "/api/content/#{ @id }"
    mediaType: 'application/vnd.org.cnx.module'

    toJSON: () ->
      json = super()
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

  # Mix in the loadable methods
  BaseModel = BaseModel.extend loadable
  return BaseModel
