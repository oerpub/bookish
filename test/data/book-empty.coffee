define ['cs!./new-book'], (newBook) ->
  return {
    content: [
      newBook
        title: 'Empty Book'
        body: """
          <nav>
            <ol></ol>
          </nav>
        """
    ]
  }
