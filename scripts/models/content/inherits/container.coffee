define [
  'jquery'
  'underscore'
  'backbone'
  'cs!models/content/inherits/base'
], ($, _, Backbone, BaseModel) ->

  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.folder'
    accept: []

    accepts: (mediaType) ->
      if (typeof mediaType is 'string')
        return _.indexOf(@accept, mediaType) is not -1

      return @accept

    initialize: (attrs) ->
      @fetch({silent: true})

    add: (model, options) ->
      @get('contents').add(model)
      if not options?.silent then @trigger('change')
      return @

    set: (key, val, options) ->
      if (key == null) then return this;

      if typeof key is 'object'
        attrs = key
        options = val
      else
        (attrs = {})[key] = val

      contents = attrs.contents
      attrs.contents = @get('contents') or new Backbone.Collection()

      if contents
        require ['cs!collections/content'], (content) =>
          content.loading().done () =>
            _.each contents, (item) =>
              @add(content.get({id: item.id}), {silent: true})
            @trigger('change:contents')

      return Backbone.Model::set.call(@, attrs, options)
