define [
  'underscore'
  'backbone'
  'cs!gh-book/uuid'
  'cs!models/content/module'
], (_, Backbone, uuid, ModuleModel) ->

  return class BinaryFileModel extends ModuleModel
    mediaType: 'application/octet-stream'
    isBinary: true

    initialize: (options) ->
      @mediaType = options.mediaType if options.mediaType
      super()

      # Give the resource an id if it does not already have one
      @id ?= "resources/#{uuid()}"


    parse: (json) ->

      @sha = json.sha
      bytes = json.content

      # The result of a Github PUT is an object instead of the new state of the model.
      # Basically ignore it.
      return bytes if 'string' != typeof bytes

      # Use the browser's Base64 encode if available
      encode = btoa or @Base64?.encode

      base64Encoded = encode(bytes)

      return {body: bytes, base64Encoded: base64Encoded}

