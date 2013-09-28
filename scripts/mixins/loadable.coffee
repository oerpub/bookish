# Loadable Mixin
# =======
#
# This provides models or collections with a `.load()` method which calls
# `.fetch()` only once.
define ['jquery'], ($) ->

  loadableMixin =

    # Since `load` checks isNew and the presence of an `id` may not be enough
    # allow a way to set `isNew()` to be true
    isNew: () ->
      # Something is new if _isNew == true/false or it does not have an id or url
      return @_isNew if @_isNew?
      # need to check if @url is a static string ('/workspace') and not a function (new Module)
      hasStaticUrl = @url and typeof(@url) != 'function'
      return !(@id or hasStaticUrl)
    setNew: () -> @_isNew = true

    # Returns a promise.
    # If this has not been fully populated it will be fetched exactly once
    load: () ->
      if not @_loading
        if @isNew?()
          promise = new $.Deferred()
          promise.resolve(@)
        else
          promise = @fetch()

        # See if we need to daisy-chain loading
        @_loading = @_loadComplex?(promise) or promise

        @_loading.fail (err) =>
          # Since we failed clear the promise so we can try again later.
          @_loading = null
          @trigger('load:fail', err)
        @_loading.done () =>
          @trigger('load:done')

      return @_loading

    # By overriding this method the subclass can load other files before
    # this model is considered loaded.
    # This method should only be called by `.load()`
    # _loadComplex: (fetchPromise) -> fetchPromise


    # Force a `Backbone.Collection` or `Backbone.Model` to reload its contents.
    # If in the middle of a `load` it waits until the load completes.
    # Returns a Promise when the reload completes.
    reload: () ->
      # Finish reloading if loading has already started
      if @_loading
        return @_loading.then () =>
          delete @_loading
          return @reload()

      else
        oldContent = @serialize()
        # For collections reset the contents to nothing
        @reset?()
        return @load().then () =>

          if oldContent != @serialize()

            isDirty = @onReloaded(oldContent)
            @set {_hasRemoteChanges: true, _isDirty: isDirty} , {parse:true}

          else
            # Otherwise, clear the bits just to be safe
            @set {_hasRemoteChanges: false, _isDirty: false} , {parse:true}


    # Hook to merge local unsaved changes into the remotely-updated model
    # `oldContent` the serialized content before remote content was fetched
    onReloaded: (oldContent) ->
      console.warn 'BUG: onReload SHOULD be implemented by subclasses'
      return false # Does **not** have local changes

  return loadableMixin
