define [
  'jquery'
  'underscore'
  'backbone'
  'github'
], ($, _, Backbone, Github, mediaTypes, XhtmlFile, OpfFile) ->


  # Nested require is so we can rebind `Backbone.sync` before any ajax calls are made.
  require [
    'cs!collections/media-types'
    'cs!gh-book/xhtml-file'
    'cs!gh-book/opf-file'
  ], (mediaTypes, XhtmlFile, OpfFile) ->

    mediaTypes.add XhtmlFile
    mediaTypes.add OpfFile


  session = new Backbone.Model()
  session.set
    'repoUser': 'philschatz'
    'repoName': 'books'
    'branch'  : 'master'
    'rootPath': ''

  getRepo = () ->
    gh = new Github()
    gh.getRepo(session.get('repoUser'), session.get('repoName'))


  writeFile = (path, text, commitText) ->
    getRepo().write session.get('branch'), "#{session.get('rootPath')}#{path}", text, commitText

  readFile =       (path) -> getRepo().read       session.get('branch'), "#{session.get('rootPath')}#{path}"
  readBinaryFile = (path) -> getRepo().readBinary session.get('branch'), "#{session.get('rootPath')}#{path}"
  readDir =        (path) -> getRepo().contents   session.get('branch'), path


  Backbone.sync = (method, model, options) ->

    path = model.id or model.url?() or model.url

    console.log method, path
    ret = null
    switch method
      when 'read' then ret = readFile(path)
      when 'update' then ret = writeFile(path, model.serialize(), 'Editor Save')
      when 'create'
        # Create an id if this model has not been saved yet
        id = _uuid()
        model.set 'id', id
        ret = writeFile(path, model.serialize())
      else throw "Model sync method not supported: #{method}"

    ret.done (value) => options?.success?(value)
    ret.fail (error) => options?.error?(ret, error)
    return ret



  # Set to true so we load the workspace
  # TODO: Workspace loading should not be dependent on this being true
  _authenticated = true

  return new (class Session extends Backbone.Model

    login: () ->
      _authenticated = true

    logout: () ->
      this.reset()
      this.clear()
      this.trigger('logout')

    reset: () ->
      _authenticated = false
      @set('user', null)

    authenticated: () ->
      return _authenticated

    user: () ->
      return @get('user')
  )()
