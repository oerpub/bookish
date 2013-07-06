define [
  'marionette'
  'hbs!gh-book/sign-in-template'
  'bootstrapModal'
], (Marionette, signInTemplate) ->

  return class SignInView extends Marionette.ItemView
    template: signInTemplate

    events:
      'click #sign-in': 'signIn'

    signIn: () ->
      # Set the username and password in the `Auth` model
      @model.set
        id:       @$el.find('#github-id').val()
        password: @$el.find('#github-password').val()
        token:    @$el.find('#github-token').val()


    onRender: () ->
      $modal = @$el.children().first()

      # attach a close listener
      $modal.on 'hidden', () => @trigger 'close'

      # Show the modal
      $modal.modal {show:true}
