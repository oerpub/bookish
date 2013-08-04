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
  'cs!collections/media-types'
  'cs!mixins/loadable'
], ($, _, Backbone, mediaTypes, loadableMixin) ->


  class Epub extends Backbone.Collection
    toJSON: -> model.toJSON() for model in @models

    # Use mediaTypes to instantiate a new Model
    model: (attrs, options) ->
      if attrs.mediaType
        Medium = mediaTypes.type(attrs.mediaType)
        # delete attrs.mediaType

        return new Medium(attrs)

      throw 'You must pass in the model or set its mediaType when adding to the content collection.'

    branches: () ->
      return _.where(@models, {branch: true})

    # Save serially.
    save: (options) ->
      # save returns a promise.
      promise = new $.Deferred()

      # Pull the next model off the queue and save it.
      # When saving has completed, save the next model.
      saveNextItem = (queue) =>
        if not queue.length
          options?.success?()
          promise.resolve(@)
          return

        model = queue.shift()
        model.save()
        .fail((err) -> promise.reject(err))
        .done () -> saveNextItem(queue)

      # Save all the models that have changes
      changedModels = @filter (model) -> model.isDirty()
      saveNextItem(changedModels)
      return promise.promise()

  Epub = Epub.extend loadableMixin

  # Load the container file
  # Done after `EPub.extend` to ensure the default load is overridden
  Epub::load = () ->
    if not @container
      @container = @model {mediaType:'application/epub+zip'}
      @add(@container, {silent:true})
    return @container.load()

  # All content in the Workspace
  return new Epub()
