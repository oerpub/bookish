# Loadable Mixin
# =======
#
# This provides models or collections with a `.load()` method which calls
# `.fetch()` only once.
define ['jquery'], ($) ->

  loadableMixin =
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
        @_loading = @_loadComplex(promise)

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
    _loadComplex: (fetchPromise) -> fetchPromise


  return loadableMixin
