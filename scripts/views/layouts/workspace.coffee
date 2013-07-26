define [
  'marionette'
  'hbs!templates/layouts/workspace'
], (Marionette, workspaceTemplate) ->

  return class Workspace extends Marionette.Layout
    template: workspaceTemplate

    regions:
      content: '#content'
      menu: '#menu'
      sidebar: '#sidebar'
