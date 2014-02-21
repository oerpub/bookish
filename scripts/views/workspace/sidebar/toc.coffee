define [
  'underscore'
  'marionette'
  'cs!collections/content'
  'cs!views/workspace/sidebar/toc-branch'
  'hbs!templates/workspace/sidebar/toc'
], (_, Marionette, allContent, TocBranchView, tocTemplate) ->

  return class TocView extends Marionette.CompositeView
    template: tocTemplate
    itemView: TocBranchView
    itemViewContainer: 'ol'

    initialize: (options) ->
      if options?.collection
        @collection = options.collection
        @showNodes = true
      else
        @collection = allContent


      # When the model updates, re-render the view
      if @model
        @listenTo @model, 'change:title', (model, value, options) =>
          @render() # FIXME: reimplement renderModelOnly() from toc-branch

      super(options)


    templateHelpers: () ->
      # For a book, show the ToC unsaved/remotely-changed icons (in the navModel, instead of the OPF file)
      model = @model?.navModel or @model

      return {
        isPicker: !@model
        mediaType: @model?.mediaType
        _isDirty: model?.get('_isDirty')
        _hasRemoteChanges: model?.get('_hasRemoteChanges')
      }

    # Used by TocBranchView to know which collection to ask for an overridden title
    itemViewOptions: () ->
      return {container: @collection, isPicker: !@model}

    # Override internal Marionette method.
    # This method adds a child list item at a given index.
    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)

    events:
      'click .toc-edit-rename': 'changeTitle'
      'click .toc-edit-metadata': 'editMetadata'

    editMetadata: (e) ->
      e.preventDefault()
      @model.triggerMetadataEdit?()

    changeTitle: () ->
      title = prompt('Enter a new Title', @model.get('title'))
      if title then @model.set('title', title)
      @render() # FIXME: reimplement renderModelOnly() from toc-branch
