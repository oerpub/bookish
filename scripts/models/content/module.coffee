define [
  'underscore'
  'backbone'
  'cs!models/content/base'
], (_, Backbone, BaseModel) ->

  # The `Content` model contains the following members:
  #
  # * `title` - an HTML title of the content
  # * `language` - the main language (eg `en-us`)
  # * `subjects` - an array of strings (eg `['Mathematics', 'Business']`)
  # * `keywords` - an array of keywords (eg `['constant', 'boltzmann constant']`)
  # * `authors` - an `Collection` of `User`s that are attributed as authors
  return BaseModel.extend
    mediaType: 'application/vnd.org.cnx.module'
    accept: []
    defaults:
      title: 'Untitled'
      subjects: []
      keywords: []
      authors: []
      copyrightHolders: []
      # Default language for new content is the browser's language
      language: navigator?.language or navigator?.userLanguage or 'en'

    contentView: (callback) ->
      # return instantiated content view
      # use require to get view and pass it in to the callback
      callback()

    menuView: () ->
      # return instantiated menu view
      callback()

    menuView: () ->
      # return instantiated menu view
      callback()
