define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  # The `Content` model contains the following members:
  #
  # * `title` - an HTML title of the content
  # * `language` - the main language (eg `en-us`)
  # * `subjects` - an array of strings (eg `['Mathematics', 'Business']`)
  # * `keywords` - an array of keywords (eg `['constant', 'boltzmann constant']`)
  # * `authors` - an `Collection` of `User`s that are attributed as authors
  return Backbone.Model.extend
    mediaType: 'application/vnd.org.cnx.module'
    defaults:
      title: 'Untitled'
      subjects: []
      keywords: []
      authors: []
      copyrightHolders: []
      # Default language for new content is the browser's language
      language: (navigator?.userLanguage or navigator?.language or 'en').toLowerCase()

    accepts: (mediaType) ->
      types = []

      if (typeof mediaType is 'string')
        return _.indexOf(types, mediaType) is not -1

      return types

    toJSON: () ->
      json = Backbone.Model::toJSON.apply(@, arguments)
      json.mediaType = @mediaType
      json.id = @id or @cid

      return json
