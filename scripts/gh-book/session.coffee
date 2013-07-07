define ['backbone'], (Backbone) ->

  session = new Backbone.Model()
  session.set
    'repoUser': 'Connexions'
    'repoName': 'atc'
    'branch'  : 'sample-book'
    'rootPath': ''
    'auth'    : 'oauth'
    'token'   : null         # Set your token here if you want

  return session
