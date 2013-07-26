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
      workspace: '#workspace'

    events:
      'click #workspace-container > .close': 'minimizeWorkspace'
      'click #sidebar-container > .close':   'minimizeSidebar'

    minimizeWorkspace: () -> @$('#workspace-container').toggleClass('minimized')
    minimizeSidebar: () -> @$('#sidebar-container').toggleClass('minimized')
