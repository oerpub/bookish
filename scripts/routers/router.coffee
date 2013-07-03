define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!controllers/routing'
], ($, _, Backbone, Marionette, routerController) ->

  return new class Router extends Marionette.AppRouter
    controller: routerController
    appRoutes:
      '':             'workspace' # Show the workspace list of content
      'workspace':    'workspace'
      'content/*id':  'edit' # Edit an existing piece of content (id can be a path)
