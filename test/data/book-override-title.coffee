define ['cs!./new-book', 'cs!./new-module'], (newBook, newModule) ->
  module = newModule {title: 'Module whose Title Should be Different in a Book ToC', body: '<p>Nothing</p>'}
  return {
    content: [
      module
      newBook {title: 'Book with Overridden Title', body: "<nav><ol><li><a href='#{module.id}'>This is an Overridden Title</a></li></ol></nav>"}
    ]
  }
