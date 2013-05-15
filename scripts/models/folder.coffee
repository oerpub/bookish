define [
  'underscore'
  'backbone'
  'cs!models/deferrable'
], (_, Backbone, Deferrable) ->

  # Folder
  # =======
  return Deferrable.extend
    defaults:
      title: 'Untitled Folder'
    mediaType: 'application/vnd.org.cnx.folder'
    initialize: ->
      Deferrable::initialize.apply(@, arguments)
      @contents = new Backbone.Collection()
    accepts: -> [ BaseBook::mediaType, BaseContent::mediaType ]
    children: -> @contents
