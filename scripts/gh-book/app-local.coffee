# This file simulates Github Reads by making a simple GET request to another
# directory on the webserver that has an unzipped EPUB.
#
# Change `PATH_PREFIX` to point to the path of the unzipped EPUB
#
# You will also need to update `scripts/config.coffee` to load `cs!gh-book/app-local` instead of `cs!app`
define [
  'jquery'
  'backbone'
  'cs!gh-book/app'
], ($, Backbone, app) ->

  PATH_PREFIX = '../books'

  console.log "NOTE: Using path to local book instead of github API: #{PATH_PREFIX}"

  # HACK to load files locally
  Backbone.sync = (method, model, options) ->

    path = model.id or model.url?() or model.url

    console.log method, path
    ret = null
    switch method
      when 'read'
        if model.isBinary
          ret = $.ajax
            beforeSend: (xhr) ->
              xhr.overrideMimeType 'text/plain; charset=x-user-defined'
            url:"#{PATH_PREFIX}/#{path}"
        else
          ret = $.ajax
            dataType: 'text'
            data: false
            url:"#{PATH_PREFIX}/#{path}"
      else
        console.error "Model sync method not supported: #{method} for #{model.id}"
        ret = $.Deferred()
        ret.resolve(model.serialize())


    # From github-client. Parse the string if isBinary
    ret = ret.then (data, textStatus, jqXHR) ->
      ret = $.Deferred()
      if model.isBinary
        # Convert raw data to binary chopping off the higher-order bytes in each char.
        # Useful for Base64 encoding.
        converted = ''
        for i in [0..data.length]
          converted += String.fromCharCode(data.charCodeAt(i) & 0xff)
        converted

        ret.resolve(converted, textStatus, jqXHR)
      else
        ret.resolve(data, textStatus, jqXHR)

    ret.done (value) => options?.success?(value)
    ret.fail (error) => options?.error?(ret, error)
    return ret
