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
], ($, _, Backbone, mediaTypes) ->


  class EPUBContainer extends Backbone.Collection
    _loaded = $.Deferred()

    defaults:
      urlRoot: ''
    url: -> 'META-INF/container.xml'

    toJSON: -> model.toJSON() for model in @models
    parse: (xmlStr) ->
      $xml = jQuery(xmlStr)
      ret = []
      $xml.find('rootfiles > rootfile').each (i, el) =>
        href = jQuery(el).attr 'full-path'
        ret.push {id: href, mediaType: 'application/oebps-package+xml'}
      return ret


    model: (attrs, options) ->
      if attrs.mediaType
        Medium = mediaTypes.type(attrs.mediaType)
        delete attrs.mediaType

        return new Medium(attrs)

      throw 'You must pass in the model or set its mediaType when adding to the content collection.'

    initialize: () ->
      @load()
      # @listenTo(session, 'login', @load)

    branches: () ->
      return _.where(@models, {branch: true})

    loading: () ->
      return _loaded.promise()

    load: () ->
      @fetch
        silent: true
        success: (model, response, options) =>
          @trigger('reset')
          _loaded.resolve()



  # All content in the Workspace
  return new EPUBContainer()
