define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/toc-branch'
], ($, _, Backbone, Marionette, tocBranchTemplate) ->

  return Marionette.CompositeView.extend
    template: tocBranchTemplate
    tagName: "li"
    itemViewContainer: '> ol'

    initialize: () ->
      @collection = @model.get('contents')

    render: () ->
      Marionette.CompositeView::render.apply(@, arguments)

      if @model and @model.expanded
        @$el.addClass('editor-node-expanded')
        @isExpanded = true
        @expand(true)
      
      return @

    events:
      # The `.editor-node-body` is needed because `li` elements render differently
      # when there is a space between `<li>` and the first child.
      # `.editor-node-body` ensures there is never a space.
      'click > .editor-node-body > .editor-expand-collapse': 'toggleExpanded'
      'click > .editor-node-body > .no-edit-action': 'toggleExpanded'
      'click > .editor-node-body > .edit-action': 'editAction'
      'click > .editor-node-body > .edit-settings': 'editSettings'

    # Toggle expanded/collapsed in the View
    # -------
    #
    # The first time a node is rendered it is collapsed so we lazily load the
    # `ItemView` children.
    #
    # Initially, the node is collapsed and the following occurs:
    #
    # 1. `@render()` calls `@_renderChildren()`
    # 2. Since `@isExpanded == false` the children are not rendered
    #
    # When the node is expanded:
    #
    # 1. `@isExpanded` is set to `true`
    # 2. `@render()` is called and calls `@_renderChildren()`
    # 3. Since `@isExpanded == true` the children are rendered and attached to the DOM
    # 4. `@hasRendered` is set to `true` so we know not to generate the children again
    #
    #
    # When an expanded node is collapsed:
    #
    # 1. `@isExpanded` is set to `false`
    # 2. A CSS class is set on the `<li>` item to hide children
    # 3. CSS rules hide the children and change the expand/collapse icon
    #
    # When a node that was expanded and collapsed is re-expanded:
    #
    # 1. `@isExpanded` is set to `true`
    # 2. Since `@hasRendered == true` there is no need to call `@render()`
    # 3. The CSS class is removed to show the children again

    isExpanded: false
    hasRendered: false

    # Called from UI when user clicks the collapse/expando buttons
    toggleExpanded: -> @expand !@isExpanded

    # Pass in `false` to collapse
    expand: (@isExpanded) ->
      @model.expanded = @isExpanded
      @$el.toggleClass 'editor-node-expanded', @isExpanded
      # (re)render the model and children if the node is expanded
      # and has not been rendered yet.
      if @isExpanded and !@hasRendered
        @render()

    # From `Marionette.CompositeView`.
    # Added check to only render when the model `@isExpanded`
    _renderChildren: ->
      if @isRendered
        if @isExpanded
          Marionette.CollectionView.prototype._renderChildren.call(@)
          this.triggerMethod('composite:collection:rendered')
        # Remember that the children have been rendered already
        @hasRendered = @isExpanded


    # Perform the edit action and then expand the node to show children.
    editAction: -> @model.editAction(); @expand(true)

    editSettings: ->
      newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', @model.get('title')

      if newTitle
        @model.set('title', newTitle)

      @render()
      ###
      if @model != @model.dereference()
        contentModel = @model.dereference()
        originalTitle = contentModel?.get('title') or @model.get 'title'
        newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', originalTitle
        if '-' == newTitle
          @model.parent?.children()?.remove @model
        else if newTitle == contentModel?.get('title')
          @model.unset 'title'
        else if newTitle
          @model.set 'title', newTitle
      else
        originalTitle = @model.get 'title'
        newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', originalTitle
        if '-' == newTitle
          @model.parent?.children()?.remove @model
        else
          @model.set 'title', newTitle if newTitle
      ###
