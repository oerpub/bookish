# Use this to generate HTML with extra divs for Drag-and-Drop zones.
#
# To update the Book model when a `drop` occurs we convert the new DOM into
# a JSON tree and set it on the model.
#
# **FIXME:** Instead of a JSON tree this Model should be implemented using a Tree-Like Collection that has a `.toJSON()` and methods like `.insertBefore()`
define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'hbs!templates/workspace/book-edit-node'
], ($, _, Backbone, Marionette, bookEditNodeTemplate) ->

  return Marionette.CompositeView.extend
    template: bookEditNodeTemplate
    tagName: 'li'
    itemViewContainer: '> ol'
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


    initialize: ->
      # grab the child collection from the parent model
      # so that we can render the collection as children
      # of this parent node
      @collection = @model.children()

      @listenTo(@model, 'change:title', @render)

      if @collection
        # If the children drop to/from 0 rerender so the (+)/(-) expandos are visible
        @listenTo @collection, 'add',    =>
          if @collection.length == 1
            @expand(true)
        @listenTo @collection, 'remove', =>
          if @collection.length == 0
            @render()
        @listenTo @collection, 'reset',  => @render()

        @listenTo @collection, 'all', (name, model, collection, options=collection) =>
          # Reduce the number of re-renderings that occur by filtering on the
          # type of event.
          # **FIXME:** Just listen to the relevant events
          switch name
            when 'change' then return
            when 'change:title' then return
            when 'change:treeNode' then return
            else @render() if @model == options?.parent

      # If the content title changes and we have not overridden the title
      # rerender the node
      if @model != @model.dereference()
        contentModel = @model.dereference()
        @listenTo contentModel, 'change:title', (newTitle, model, options) =>
          @render() if !@model.get 'title'


    templateHelpers: ->
      return {
        children: @collection?.length
        # Some rendered nodes are pointers to pieces of content. include the content.
        content: @model.dereference().toJSON() if @model != @model.dereference()
        editAction: !!@model.editAction
        parent: !!@model.parent
      }


    onRender: ->

      @$el.attr 'data-media-type', @model.mediaType
      $body = @$el.children '.editor-node-body'

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>
        _EnableContentDragging(@model, $body.children '*[data-media-type]')

        validSelectors = _.map @model.accepts(), (mediaType) -> "*[data-media-type=\"#{mediaType}\"]"
        validSelectors = validSelectors.join ','

        expandTimeout = null
        expandNode = => @toggleExpanded(true) if @collection?.length > 0

        $body.children('.editor-drop-zone').add(@$el.children('.editor-drop-zone')).droppable
          greedy: true
          addClasses: false
          accept: validSelectors
          activeClass: 'editor-drop-zone-active'
          hoverClass: 'editor-drop-zone-hover'
          # If hovering over a node that has children but is not expanded
          # Expand after a period of time.
          # over: => expandTimeout = setTimeout(expandNode, Models.config.get('delayBeforeSaving'))
          # out: => clearTimeout expandTimeout

          drop: (evt, ui) =>
            # Possible drop cases:
            #
            # - On the node
            # - Before the node
            # - After the node

            $drag = ui.draggable
            $drop = $(evt.target)

            # Perform all of these DOM cleanup events once jQueryUI is finished with its events
            delay = =>

              drag = $drag.data('editor-model')

              # Ignore if you drop on yourself or your children
              testNode = @model
              while testNode
                return if (drag.cid == testNode.cid) or (testNode.id and drag.id == testNode.id)
                testNode = testNode.parent

              if $drop.hasClass 'editor-drop-zone-before'
                col = @model.parent.children()
                index = col.indexOf(@model)
                @model.parent.addChild drag, index
              else if $drop.hasClass 'editor-drop-zone-after'
                col = @model.parent.children()
                index = col.indexOf(@model)
                @model.parent.addChild drag, index + 1
              else if $drop.hasClass 'editor-drop-zone-in'
                @model.addChild drag
              else
                throw 'BUG. UNKNOWN DROP CLASS'

            setTimeout delay, 100

    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)
