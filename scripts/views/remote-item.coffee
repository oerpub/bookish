define [
  'marionette'
], (Marionette) ->

  class RemoteItemView extends Marionette.ItemView
    isLoaded: false

    initialize: (options) ->
      super(options)
      @model.load().done () => @isLoaded = true

    templateHelpers: () -> {isLoaded:@isLoaded}

  class RemoteCompositeView extends Marionette.CompositeView
    isLoaded: false

    initialize: (options) ->
      super(options)
      @model.load().done () => @isLoaded = true

    templateHelpers: () -> {isLoaded:@isLoaded}

  return {
    RemoteItemView:RemoteItemView
    RemoteCompositeView:RemoteCompositeView
  }
