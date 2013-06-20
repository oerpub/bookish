define [
  'underscore'
  'backbone'
  'cs!models/content/inherits/base'
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
    loaded: false
    defaults:
      title: 'Untitled'
      subjects: []
      keywords: []
      analytics: []
      copyrightHolders: []
      authors: []
      editors: []
      translators: []
      # Default language for new content is the browser's language
      language: navigator?.language or navigator?.userLanguage or 'en'

    contentView: (callback) ->
      require ['cs!views/workspace/content/layouts/editor'], (View) =>
        view = new View({model: @})
        callback(view)

        if not @loaded
          @fetch
            success: (model, response, options) =>
              @loaded = true
              @trigger('loaded')

    toolbarView: (callback) ->
      require ['cs!views/workspace/menu/toolbar-aloha'], (view) ->
        callback(view)
