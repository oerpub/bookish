define [
  'backbone'
  'underscore'
  'jquery'
  'cs!collections/content'
  'cs!models/content/inherits/saveable'
  'cs!mixins/tree'
], (Backbone, _, $, allContent, SaveableModel, treeMixin) ->

  # Mixin the tree before so TocNode can override `addChild`
  SaveableTree = SaveableModel.extend(treeMixin)

  return class TocNode extends SaveableTree # Extend SaveableModel so you can get the isDirty for saving

    mediaType:  null # Subclass must define
    accept:     null # Subclass must define

    initialize: (options) ->
      throw new Error 'BUG: subclass must define mediaType'     if not @mediaType
      throw new Error 'BUG: subclass must define accept array'  if not @accept

      super(options)
      # Chapter nodes have their title passed in as an option (TODO: should be an attribute.... grr)
      if options.title
        @set('title', options.title, {parse:true})
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, value, options) =>
        @trigger 'tree:change', model, @, options

      @_initializeTreeHandlers(options)

    # Prevent the asterisk since TocNode elements are not actually Saveable (but OPF is)
    # TODO: Fix this once the editor can create new OPF files
    isNew: () -> false

    # Views rely on the mediaType to be set in here
    # TODO: Fix it in the view's `templateHelpers`
    toJSON: () ->
      json = super()
      json.mediaType = @mediaType
      return json
