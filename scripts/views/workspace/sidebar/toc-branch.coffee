define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!helpers/enable-dnd'
  'hbs!templates/workspace/sidebar/toc-branch'
], ($, _, Backbone, Marionette, EnableDnD, tocBranchTemplate) ->

  return class TocBranchView extends Marionette.CompositeView
    tagName: "li"
    itemViewContainer: '> ol'

    initialize: (options) ->
      @template = (data) =>
        data.id = @model.id
        return tocBranchTemplate(data)

      @collection = @model.getChildren?()
      @itemViewOptions = {container: @collection}
      @container = options.container

      @listenTo @model, 'change', (model, collection, options) =>
        @renderModel() if model == @model

      if @collection
        @listenTo @collection, 'add remove', (model, collection, options) =>
          if collection == @collection
            # Figure out if the expanded state has changed (see if we need to re-render the model)
            @renderModel()


    render: () ->
      result = super()

      if @model?.expanded
        @$el.addClass('editor-node-expanded')
        @_renderChildren()
      else
        @$el.removeClass('editor-node-expanded')

      # Add DnD options to content
      EnableDnD.enableContentDnD(@model, @$el.find('> .editor-node-body > *[data-media-type]'))

      if @model.getParent?()
        EnableDnD.enableDropAfter(@model, @model.getParent(), @$el.find('> .editor-drop-zone-after'))

      return result

    templateHelpers: () ->
      return {
        hasParent: !! @model.getParent?()
        hasChildren: !! @model.getChildren?()?.length
        isExpanded: @expanded
      }

    # Override Marionette's renderModel() so we can replace the title
    # if necessary without affecting the model itself
    renderModel: () ->
      data = {}
      data = @serializeData()
      data.title = @container?.getTitle?(@model) or data.title
      data = @mixinTemplateHelpers(data)

      template = @getTemplate()
      return Marionette.Renderer.render(template, data)

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
      # The `.editor-node-body` is needed because `li` elements render differently
      # when there is a space between `<li>` and the first child.
      # `.editor-node-body` ensures there is never a space.
      'click > .editor-node-body > .editor-expand-collapse': 'toggleExpanded'
      'click > .editor-node-body > .edit-settings': 'editSettings'

    # Toggle expanded/collapsed in the View
    # -------
    #
    # The first time a node is rendered it is collapsed so we lazily load the
    # `ItemView` children.
    #
    # Initially, the node is collapsed and the following occurs:
    #
    # 1. `@render()` calls `@renderChildren()`
    # 2. Since `@isExpanded == false` the children are not rendered
    #
    # When the node is expanded:
    #
    # 1. `@model.expanded` is set to `true`
    # 2. `@render()` is called and calls `@renderChildren()`
    # 3. Since `@model.expanded == true` the children are rendered and attached to the DOM
    # 4. `@hasRendered` is set to `true` so we know not to generate the children again
    #
    #
    # When an expanded node is collapsed:
    #
    # 1. `@model.expanded` is set to `false`
    # 2. A CSS class is set on the `<li>` item to hide children
    # 3. CSS rules hide the children and change the expand/collapse icon
    #
    # When a node that was expanded and collapsed is re-expanded:
    #
    # 1. `@model.expanded` is set to `true`
    # 2. Since `@hasRendered == true` there is no need to call `@render()`
    # 3. The CSS class is removed to show the children again

    # Called from UI when user clicks the collapse/expando buttons
    toggleExpanded: -> @expand(!@model.expanded)

    # Pass in `false` to collapse
    expand: (expanded) ->
      @model.expanded = expanded
      @render()

    editSettings: ->
      title = prompt('Edit Title:', @model.getTitle(@container))
      if title then @model.setTitle(@container, title)

      @render()
