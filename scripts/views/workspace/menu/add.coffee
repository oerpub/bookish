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
      'click .add-content-item': 'showCreateModal'

    showCreateModal: ->
      modal = $('#create-book-modal')
      submit = modal.find('button[data-submit]')
     
      submit.off('click').click(@addItem)

      modal.modal {show:true}

    addItem: (e) =>
      # No context means we are adding to the workspace and all content is allowed
      if @context
        if not (@model.id in @context.accept) # @model.id is a mediaType
          throw new Error 'BUG: Trying to add a type of content that is not allowed to be in this thing'

      title = $('#create-book-modal').find('input').val() || 'Untitled'

      # The options passed to the constructor are mostly for TocNode
      model = new (@model.get('modelType')) {title: title, root: @context}

      # Only add Models to `allContent` if they can be saved.
      #
      # ToC Sections, for example, cannot be saved but do implement Saveable because OpfFile extends TocNode
      # So we use `.load` instead.
      if model.load
        allContent.add(model)

      # Add the model to the context
      if @context
        @context.addChild(model)

      # Begin editing certain media as soon as they are added.
      model.addAction?(@context)

    initialize: (options) ->
      # Remember where this new content should be added
      @context = options.context

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
