Backbone = null
TocNode = null

describe 'A Toc Node', ->

  it 'should exist', ->
    runs () ->
      require ['backbone', 'cs!gh-book/toc-node'], (a, b) ->
        Backbone = a
        TocNode = b

    waitsFor () -> TocNode

    runs () ->
      x = new TocNode {root: @, title: 'TITLE'}
      expect(x.get 'title').toBe 'TITLE'

