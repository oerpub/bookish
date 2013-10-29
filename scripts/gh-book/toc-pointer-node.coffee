define ['cs!models/content/toc-pointer-node'], (TocPointerNode) ->

  class GhTocPointerNode extends TocPointerNode
    initialize: (options) ->
      model = options.model
      if model
        # When the title changes on the XhtmlModel update it in the ToC as well
        model.on 'change:title', () => @set('title', model.get('title'))
        # Set the title on the model now
        @set('title', model.get('title'))

        options.title ?= model.get('title')
      super(options)
