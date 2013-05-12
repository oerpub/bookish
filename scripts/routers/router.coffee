define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!controllers/routing'
], ($, _, Backbone, Marionette, routerController) ->

  return new (Marionette.AppRouter.extend
    controller: routerController
    appRoutes:
      '':             'workspace' # Show the workspace list of content
      'workspace':    'workspace'
      'content/:id':  'editModelId' # Edit an existing piece of content
  )()
