# Fully loading Content
# =======
# A model representing a piece of content may have been instantiated
# (ie an entry as a result of a search) but not fetched yet.
#
# When dealing with a model (except for `id`, `title`, or `mediaType`)
# be sure to call `.loaded().done(cb).fail(cb)` first.
#
# Once the model is loaded (fetched) call the callbacks.

define [
  'jquery'
  'underscore'
  'backbone'
  'cs!models/base-model'
], ($, _, Backbone, BaseModel) ->

  return BaseModel.extend
    # Returns a promise that the piece of content will be fully populated from
    # the server.
    # Initially the content is partially populated from a Search result, folder
    # listing, or some other method that allowed the user to 'click' on to begin
    # viewing/editing the full piece of content.
    loaded: (flag=false) ->
      if flag or @isNew()
        deferred = $.Deferred()
        deferred.resolve @
        @_promise = deferred.promise()
        # Mark it as loaded for the views.
        # By setting an attribute views can listen to a change and rerender,
        # replacing the progress bar with the actual view
        @set {_done: true}

      # Silently update the model (the user has not seen the model yet)
      # so `model.hasChanged()` returns `false` (to know when to enable Saving)
      if not @_promise or 'rejected' == @_promise.state()
        @set {_loading: true}
        # **TODO:** Set `silent:true` during the fetch (So save doesn't trigger)
        # but make sure all the views listen to `change:_done` so they always update
        # instead of relying on `change:*`.
        @_promise = @fetch
          success: => @set {_isDirty:false}
          error: (model, message, options) =>
            @trigger 'error', model, message, options
        @_promise
        .progress (progress) =>
          @set {_progress: progress}
        .done =>
          # Once we are done fetching and the change events have fired
          # clear all the `.changed` flag so save does not think it has dirty models
          delete @changed
          @set {_done: true}
        .fail (error) =>
          @trigger 'error', error

      return @_promise
