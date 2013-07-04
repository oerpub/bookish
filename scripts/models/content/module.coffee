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
  return class Module extends BaseModel
    mediaType: 'application/vnd.org.cnx.module'
    accept: []
    defaults:
      title: 'Untitled'
      subjects: []
      keywords: []
      googleTrackingID: []
      copyrightHolders: []
      authors: []
      editors: []
      translators: []
      # Default language for new content is the browser's language
      language: navigator?.language or navigator?.userLanguage or 'en'

    # Begin editing this medium as soon as it is added
    addAction: () ->
      id = @id or @cid
      require ['cs!routers/router'], (router) ->
        router.navigate("content/#{ id }", {trigger: true});

    # Change the content view when editing this
    contentView: (callback) ->
      require ['cs!views/workspace/content/layouts/editor'], (View) =>
        view = new View({model: @})
        callback(view)

    # Change the toolbar view when editing this
    toolbarView: (callback) ->
      require ['cs!views/workspace/menu/toolbar-aloha'], (view) ->
        callback(view)
