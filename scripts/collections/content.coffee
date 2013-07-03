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
  'cs!mixins/loadable'
], ($, _, Backbone, session, mediaTypes, loadable) ->

  class AllContent extends Backbone.Collection
    url: '/api/content'

    initialize: () ->
      if session.authenticated() then @load()

      @listenTo(session, 'login', @load)

    model: (attrs, options) ->
      if attrs.mediaType
        mediaType = attrs.mediaType
        Medium = mediaTypes.type(mediaType)

        return new Medium(attrs)

      throw 'You must pass in the model or set its mediaType when adding to the content collection.'

    branches: () ->
      return _.where(@models, {branch: true})


    # Extend the `load()` to wait until all content is loaded
    _loadComplex: (fetchPromise) ->
      promise = new $.Deferred()
      fetchPromise.done () =>
        contentPromises = @map (model) => model.load()
        $.when.apply($, contentPromises).done () =>
          promise.resolve(@)
          @trigger('change')
      return promise


    loading: () ->
      return @load().promise()


    save: (options) ->
      # Save serially.
      # Pull the next model off the queue and save it.
      # When saving has completed, save the next model.
      saveNextItem = (queue) =>
        if not queue.length
          options?.success?()
          return

        model = queue.shift()
        model.save()
        .fail((err) -> throw err)
        .done () -> saveNextItem(queue)

      # Save all the models that have changes
      changedModels = @filter (model) -> model.hasChanged()
      saveNextItem(changedModels)


  # Mix in the loadable methods
  AllContent = AllContent.extend loadable

  return new AllContent()
