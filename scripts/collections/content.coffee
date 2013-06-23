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

  return new (Backbone.Collection.extend
    url: '/api/content'

    initialize: () ->
      if session.authenticated() then @load()

      @listenTo(session, 'login', @load)

    model: (attrs, options) ->
      if attrs.mediaType
        Medium = mediaTypes.type(attrs.mediaType)
        delete attrs.mediaType

        return new Medium(attrs)

      throw 'You must pass in the model or set its mediaType when adding to the content collection.'

    branches: () ->
      return _.where(@models, {branch: true})

    load: () ->
      @fetch
        silent: true
        success: (model, response, options) =>
          @trigger('reset')
          _loaded.resolve()

    add: (models, options) ->
      if (!_.isArray(models)) then (models = if models then [models] else [])

      # Listen to models and trigger a change event if any of them change
      _.each models, (model, index, arr) =>
        @listenTo(model, 'change', () => @trigger('change'))
        @listenTo(model, 'change:contents', () => @trigger('change:contents'))

      Backbone.Collection::add.call(@, models, options)

    loading: () ->
      return _loaded.promise()

    save: (options) ->
      newModels = []
      models = []

      _.each @models, (model, index, arr) ->
        if not model.id
          newModels.push(model)

      $.post '/api/contents', newModels, (data) =>
        # Update ids
        _.each data, (model, index, arr) =>
          @models.get(model.cid).set('id', model.id)

        _.each @models, (model, index, arr) ->
          if model.dirty
            models.push(model)

        $.ajax
          type: "PATCH"
          url: '/api/contents'
          data: models
          success: (data, textStatus, $xhr) ->
            console.log 'successfuly updated'
            options?.success?()

      return @
  )()