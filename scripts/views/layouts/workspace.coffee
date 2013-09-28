define [
  'marionette'
  'cs!session'
  'cs!views/workspace/menu/auth'
  'hbs!templates/layouts/workspace'
], (Marionette, session, AuthView, workspaceTemplate) ->

  # This layout looks as follows:
  #
  #     | ---------------------------------------------------------------- |
  #     |                                                                  |
  #     | ----------- | --------- | -------------------------------------- |
  #     |          X  |        X  | [menu: Home, Toolbar, Signin/Signout]  |
  #     |             |           |                                        |
  #     | [workspace] | [sidebar] | [content]                              |
  #     |             |           |                                        |
  #     | ----------- | --------- | -------------------------------------- |
  #
  return class Workspace extends Marionette.Layout
    template: workspaceTemplate

    regions:
      workspace:  '#workspace'
      sidebar:    '#sidebar'
      menu:       '#menu'
      content:    '#content'
      auth:       '#workspace-auth'

    onShow: () ->
      @auth.show(new AuthView {model: session})


    showWorkspace: (b) -> # There is some other code that calls this and should be removed
    showToc: (b) ->       # There is some other code that calls this and should be removed
