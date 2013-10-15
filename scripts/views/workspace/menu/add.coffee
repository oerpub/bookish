define [
  'marionette'
  'cs!collections/content'
  'hbs!templates/workspace/menu/add'
  'hbs!templates/workspace/menu/add-item'
  'bootstrapDropdown'
], (Marionette, allContent, addTemplate, addItemTemplate) ->

  UNTITLED = 'Untitled'

  class AddItemView extends Marionette.ItemView
    tagName: 'li'

    template: addItemTemplate

    events:
      'click .add-content-item': 'addItem'

    initialize: (options) ->
      # Remember where this new content should be added
      @context = options.context

    addItem: (e) ->
      e.preventDefault()

      # No context means we are adding to the workspace and all content is allowed
      if @context
        if not (@model.id in @context.accept) # @model.id is a mediaType
          throw new Error 'BUG: Trying to add a type of content that is not allowed to be in this thing'

      title = prompt('What title would you like to use for this?') || 'Untitled'

      # The options passed to the constructor are mostly for TocNode
      model = new (@model.get('modelType')) {title: title, root: @context}

      # Only add Models to `allContent` if they can be saved.
      #
      # ToC Sections, for example, cannot be saved but do implement Saveable because OpfFile extends TocNode
      # So we use `.id` instead.
      if model.id
        allContent.add(model)

      # Add the model to the context
      if @context
        @context.addChild(model)

      # Begin editing certain media as soon as they are added.
      model.addAction?()

  return class AddView extends Marionette.CompositeView
    initialize: (options) ->
      # Remember where this new content should be added
      @context = options.context

    template: addTemplate
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'

    itemViewOptions: (model, index) ->
      return {context: @context}
