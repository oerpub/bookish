define ['cs!./book-big', 'cs!./new-folder'], (bigBook, newFolder) ->
  folderContents = ({id:content.id, title:content.title, mediaType:content.mediaType} for content in bigBook.content)

  contentWithFolder = bigBook.content.slice 0
  contentWithFolder.push newFolder
    title: 'Big Folder'
    contents: folderContents

  return {
    content: contentWithFolder
  }
