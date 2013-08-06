define [
  'marionette'
  'hbs!gh-book/loading-template'
  'bootstrapModal'
], (Marionette, loadingTemplate) ->

  return class LoadingView extends Marionette.ItemView
    template: loadingTemplate

    # This view is given a `promise` that notifies when progress happens
    initialize: (options) ->
      # HACK: Marionette does not seem to use template if the view is not an ItemView
      @$el.append(loadingTemplate())


      promise = options.promise or @model.load()

      complete = 0
      total = 0

      promise.progress (msg) =>
        $loadingText = @$el.find('#loading-text')
        $loadingBar = @$el.find('#loading-bar')

        switch msg.type
          when 'start'  then total++    ; $loadingText.text("Loading #{msg.path}")
          when 'end'    then complete++ ; $loadingText.text("Loaded #{ msg.path}")

        setTimeout (() =>
          percentage = 100 * complete / total
          $loadingBar.attr('style', "width: #{percentage}%;")
        ), 1

      promise.fail (msg) =>
        $loadingText = @$el.find('#loading-text')
        $loadingBar = @$el.find('#loading-bar')
        $loadingText.text('There was a problem loading the workspace. Possible problems: Username/Password mismatch, Invalid Repository (it needs a META-INF/contents.xml), or some other network problem. Please refresh and try again.')
