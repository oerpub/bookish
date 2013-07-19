# Listed below are various content generators.
# Feel free to comment out ones you do not want to load for testing purposes
DEPENDENCIES = [
  'cs!mock/module-simple'
  'cs!mock/book-empty'
  'cs!mock/book-simple'

  'cs!mock/book-override-title'
  'cs!mock/book-big' # Adds a TON of modules into the workspace
  'cs!mock/book-tree-simple'
  # 'cs!mock/book-tree-big'

  'cs!mock/folder-empty'
  'cs!mock/folder-simple'
  'cs!mock/folder-big' # Uses modules in `book-big`
  'cs!mock/folder-mixed'

  # 'cs!mock/module-image'
  'cs!mock/modules-cycle'


  'cs!mock/module-metadata'
  'cs!mock/book-metadata'
]

define DEPENDENCIES, () ->
  allContent = []
  allResources = {}

  # Each dependency contains a `.content` and optionally a `.resources`
  # - `.content` is an array of objects that represent the content (Module, Book, Folder)
  #              to be added to the workspace
  # - `.resources` is an object whose key is a hash id and value is a binary string
  #                representing things like images, java applets, etc.
  for dep in arguments
    for fields in dep.content
      allContent.push(fields)
    if dep.resources
      for hash, bytes of dep.resources
        allResources[hash] = bytes

  return {content: allContent, resources: allResources}
