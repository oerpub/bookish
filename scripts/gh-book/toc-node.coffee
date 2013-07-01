define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
  'cs!gh-book/xhtml-file'
], (_, Backbone, BaseContainerModel, XhtmlFile) ->

  mediaType = 'application/vnd.org.cnx.folder'

  class TocNode extends BaseContainerModel
    defaults:
      title: 'Untitled Section'

    mediaType: mediaType
    accept: [mediaType, XhtmlFile::mediaType]

    initialize: (options) ->
      throw 'BUG: Missing constructor options' if not options
      throw 'BUG: Missing title' if not options.title

      @children = new Backbone.Collection()
      @set 'title', options.title
      @htmlAttributes = options.htmlAttributes or {}

      @on 'change:title', (model, options) =>
        @trigger 'tree:change', model, @, options

      @children.on 'add', (child, collection, options) =>
        # Parent is useful for DnD but since we don't use a `TocNode`
        # for the leaves (`Module`) the view needs to pass the
        # model in anyway, so it's commented.
        #
        child.parent = @
        child.root = @root
        @trigger 'tree:add', child, collection, options

      @children.on 'remove', (child, collection, options) =>
        delete child.parent
        delete child.root
        @trigger 'tree:remove', child, collection, options

      @children.on 'change', (child, collection, options) =>
        @trigger 'tree:change', child, collection, options

      trickleEvents = (name) =>
        @children.on name, (model, collection, options) =>
          @trigger name, model, collection, options

      # Trickle up tree change events so the Navigation HTML
      # updates when the nodes or title changes
      trickleEvents 'tree:add'
      trickleEvents 'tree:remove'
      trickleEvents 'tree:change'

    getChildren: () -> @children
