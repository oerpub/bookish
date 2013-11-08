define ['underscore', 'cs!./toc-node'], (_, TocNode) ->

  class TocPointerNode extends TocNode
    mediaType: 'application/BUG-mediaType-not-set' # This will get overridden to be whatever this node points to
    accept: []      # This will get overridden to be whatever this node points to

    initialize: (options) ->
      throw 'BUG: Missing constructor options' if not options
      throw 'BUG: Missing model this points to' if not options.model

      # Shadow properties/events on the original model
      @model = options.model
      @mediaType = @model.mediaType
      @accept = @model.accept

      # When contentView is null then clicking on it will not open
      # the content in the content pane.
      # A Book has a null contentView but a Module has a contentView
      # so, only set the contentView if one is set
      if @model.contentView
        @contentView = (callback) => @model.contentView(callback)


      # Should be used ONLY for serializing to HTML tree
      @id = @model.id

      if options.passThroughChanges
        @on 'change:title', (model, value, options) => @model.set('title', value, options)

      @model.on 'all', () =>
        # Since some views use filteredCollection (which uses the `model` argument in the event handler, splice in the pointer)
        # This causes problems when filteredCollection tries to keep its collection in sync.
        # Replace the 2nd arg (the @model) with the pointer (@)
        args = _.toArray(arguments)
        throw new Error 'BUG: Expecting 2nd argument to be the model this pointer points to' if @model != args[1]
        args.splice(1, 1, @)
        @trigger.apply @, args

      # Set the title on the model if an overridden one has not been set (github-book "shortcut")
      # TODO: see how the github-book works with these 2 lines commented: @set('title', @model.get('title')) if not options.title
      # options.title = options.title or @model.get 'title'
      super(options)

    # Pass through all model attributes except the title (if it is set)
    toJSON: () ->
      json = @model.toJSON()
      # If the title is overridden, change it in the json
      title = @get('title')
      json.title = title if title
      return json

    # Returns the model this points to.
    # Existence of this method means this is a pointer node
    dereferencePointer: () -> @model

    contentView: null
