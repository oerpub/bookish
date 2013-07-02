# All Content
# =======
#
# To prevent multiple copies of a model from floating around a single
# copy of all referenced content (loaded or not) is kept in this Collection
#
# This should be read-only by others
# New content models should be created by calling `ALL_CONTENT.add {}`

define [
  'jquery'
  'underscore'
  'backbone'
  'cs!session'
  'cs!collections/media-types'
], ($, _, Backbone, session, mediaTypes) ->

  _loaded = $.Deferred()

  return new class Content extends Backbone.Collection
    url: '/api/content'

    initialize: () ->
      if session.authenticated() then @load()

      @listenTo(session, 'login', @load)

    model: (attrs, options) ->
      if attrs.mediaType
        mediaType = attrs.mediaType
        Medium = mediaTypes.type(mediaType)
        # Include the `mediaType` in case models support multiple media types (like images).
        #delete attrs.mediaType

        return new Medium(attrs)

      throw 'You must pass in the model or set its mediaType when adding to the content collection.'

    branches: () ->
      return _.where(@models, {branch: true})

    load: () ->
      promises = []

      @fetch
        success: (data, response, options) =>
          _.each data.models, (model) ->
            if typeof model.promise is 'function'
              promises.push(model.promise())

          _loaded.resolve()

          $.when.apply($, promises).done () =>
            @trigger('change')

    loading: () ->
      return _loaded.promise()
