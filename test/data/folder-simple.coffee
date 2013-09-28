define ['cs!./new-module', 'cs!./new-folder'], (newModule, newFolder) ->
  module = newModule {title: 'Module in a Simple Folder', body: '<p>Nothing</p>'}
  return {
    content: [
      module
      newFolder
        title: 'Simple Folder'
        contents: [{id:module.id, title:module.title, mediaType:module.mediaType}]
    ]
  }
