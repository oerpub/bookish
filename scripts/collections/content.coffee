# All Content
# =======
#
# To prevent multiple copies of a model from floating around a single
# copy of all referenced content (loaded or not) is kept in this Collection
#
# This should be read-only by others
# New content models should be created by calling `ALL_CONTENT.add {}`

define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return new (Backbone.Collection.extend
    model: (attrs, options) ->
      throw 'You must pass the model in when adding to the content collection.'

    branches: () ->
      return _.where(@models, {branch: true})

    add: (models, options) ->
      if (!_.isArray(models))
        models = if models then [models] else []

      # Listen to models and trigger a change event if any of them change
      _.each(models, (model, index, arr) =>
        @listenTo(model, 'change', () => @trigger('change'))
      )

      Backbone.Collection::add.call(@, models, options)
  )()
