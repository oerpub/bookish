define [
  'underscore'
  'backbone'
], (_, Backbone) ->

  return new (class App extends Backbone.Model
    defaults:
      delayBeforeSaving: 3000
      metadataSubjects: ['Arts', 'Mathematics and Statistics', 'Business',
        'Science and Technology', 'Humanities', 'Social Sciences']
  )()
