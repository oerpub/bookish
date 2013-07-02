define [
  'jquery'
  'underscore'
  'backbone'
], ($, _, Backbone) ->

  class BaseModel extends Backbone.Model
    url: () -> return "/api/content/#{ @id }"
    mediaType: 'application/vnd.org.cnx.module'

    load: () ->
      if not @_loading
        if @isNew()
          @_loading = new $.Deferred()
          @_loading.resolve(@)
        else
          @_loading = @fetch()
        @_loading.done () =>
          @trigger('loaded')

      return @_loading

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
