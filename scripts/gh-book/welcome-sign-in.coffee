define [
  'marionette'
  'cs!views/workspace/menu/auth'
  'hbs!gh-book/welcome-sign-in-template'
  'bootstrapModal'
], (Marionette, AuthView, signInTemplate) ->

  return class SignInView extends AuthView
    template: signInTemplate
