REQUIRE = (if exports? then require else define)

Backbone = null
TocNode = null

describe 'A Toc Node Mixin2', ->

  it 'should exist', ->
    runs () ->
      require ['backbone', 'cs!gh-book/toc-node'], (a, b) ->
        Backbone = a
        TocNode = b

    waitsFor () -> TocNode

    runs () ->
      x = new TocNode {root: @, title: 'TITLE'}
      expect(x.get 'title').toBe 'TITLE'

