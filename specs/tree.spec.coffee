define ['backbone', 'cs!mixins/tree'], (Backbone, treeMixin) ->

  class TreeNode extends Backbone.Model
    initialize: (options={}) ->
      options.root = @ if not options.root
      @_initializeTreeHandlers(options)

  # Add in the mixin we are testing
  TreeNode = TreeNode.extend treeMixin


  describe 'A Tree Node Mixin', ->

    it 'should exist', ->
      expect(treeMixin).toBeDefined()

    it 'should initially have an empty Collection', ->
      node = new TreeNode()
      expect(node.getChildren().length).toBe 0

