define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/base'
], (_, Backbone, BaseModel) ->

  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.folder'
    accept: []

    accepts: (mediaType) ->
      if (typeof mediaType is 'string')
        return _.indexOf(@accept, mediaType) is not -1

      return @accept

    initialize: (attrs) ->
      @fetch
        success: (model, response, options) =>
          @set('contents', new Backbone.Collection())
          if response?.contents
            require ['cs!collections/content'], (content) =>
              _.each response.contents, (item) =>
                @add(content.get({id: item.id}))

        error: (model, response, options) =>
          @set('contents', new Backbone.Collection())

    add: (model) ->
      @get('contents').add(model)
      @trigger('change')
      return @
