define [
  'jquery'
  'underscore'
  'backbone'
  'github'
  'cs!helpers/logger'
], ($, _, Backbone, Github, logger) ->


  # Nested require is so we can rebind `Backbone.sync` before any ajax calls are made.
  require [
    'cs!app'
    'cs!collections/media-types'
    'cs!gh-book/xhtml-file'
    'cs!gh-book/opf-file'
    'cs!gh-book/binary-file'
  ], (app, mediaTypes, XhtmlFile, OpfFile, BinaryFile) ->

    mediaTypes.add XhtmlFile
    mediaTypes.add OpfFile
    mediaTypes.add BinaryFile, {mediaType:'image/png'}
    mediaTypes.add BinaryFile, {mediaType:'image/jpg'}
    mediaTypes.add BinaryFile, {mediaType:'image/jpeg'}

    app.start()


  # Stop logging.
  logger.stop()


  session = new Backbone.Model()
  session.set
    'repoUser': 'Connexions'
    'repoName': 'atc'
    'branch'  : 'sample-book'
    'rootPath': ''
    'auth'    : 'oauth'
    'token'   : null         # Set your token here if you want

  getRepo = () ->
    gh = new Github(session.toJSON())
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
      when 'read'
        if model.isBinary
          ret = readBinaryFile(path)
        else
          ret = readFile(path)
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


  # Custom routes to configure the Github User and Repo from the browser
  class GithubRouter extends Backbone.Router
    routes:
      '':                                 'justStart'
      'repo/:repoUser/:repoName':         'configRepo'
      'repo/:repoUser/:repoName/:branch': 'configRepo'

    justStart: () ->
      # HACK: Another async require so we don't start fetching prematurely.
      require ['cs!controllers/routing'], (controller) ->
        # Open the workspace
        controller.workspace()

    configRepo: (repoUser, repoName, branch='master') ->
      session.set
        'repoUser': repoUser
        'repoName': repoName
        'branch': branch

      @justStart()

  new GithubRouter()
  Backbone.history.start() if not Backbone.History.started
