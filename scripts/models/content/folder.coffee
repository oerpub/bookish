define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/container'
], (_, Backbone, BaseContainerModel) ->

  return class Folder extends BaseContainerModel
    defaults:
      title: 'Untitled Folder'

    mediaType: 'application/vnd.org.cnx.folder'
    accept: [
      'application/vnd.org.cnx.collection', # Book
      'application/vnd.org.cnx.module' # Module
    ]

    # The structure of Folder requires that it look something like:
    #
    #     {..., contents: ['id1', 'id2']}
    #
    # For Sidebar rendering those child models are in `@getChildren()`.
    # Pull them out and generate the simple array shown above.
    toJSON: () ->
      json = super()

      json.contents = @getChildren().map (child) =>
        console.warn 'TODO: adding new content to a folder is not supported yet' if child.isNew()
        return child.id

      return json
