define [
  'marionette'
  'cs!controllers/routing'
  'less!styles/main.less'
], (Marionette, appController) ->

  return new class Router extends Marionette.AppRouter
    controller: appController
    appRoutes:
      '':             'goWorkspace' # Show the workspace list of content
      'workspace':    'goWorkspace'
      'edit/*id':     'goEdit' # Edit an existing piece of content (id can be a URL-encoded path)
