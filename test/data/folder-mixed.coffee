define ['cs!./new-module', 'cs!./new-book', 'cs!./new-folder'], (newModule, newBook, newFolder) ->
  module = newModule {title: 'Module in a Folder and a Book', body: '<p>Nothing</p>'}
  book = newBook
    title: 'Book in a Folder'
    body: """
      <nav>
        <ol>
          <li><a href="#{module.id}">In a Book and Folder (overridden title)</a></li>
        </ol>
      </nav>
      """
  return {
    content: [
      module
      book
      newFolder
        title: 'Folder With Book and Module in it'
        contents: [
          {id:module.id,  title:module.title, mediaType:module.mediaType}
          {id:book.id,    title:book.title,   mediaType:book.mediaType}
        ]
    ]
  }
