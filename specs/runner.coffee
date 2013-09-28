# `jasmine-node` will run everything matching "*.spec.coffee" but the browser
# version needs the list of spec tests and a runner.

SPECS = [
  'cs!specs/tree.spec'
  'cs!specs/toc-node.spec'
]

require SPECS, ->
  jasmineEnv = jasmine.getEnv()
  jasmineEnv.updateInterval = 250

  ###
  Create the `HTMLReporter`, which Jasmine calls to provide results of each spec and each suite.
  The Reporter is responsible for presenting results to the user.
  ###
  htmlReporter = new jasmine.HtmlReporter()
  jasmineEnv.addReporter htmlReporter

  ###
  Delegate filtering of specs to the reporter.
  Allows for clicking on single suites or specs in the results to only run a subset of the suite.
  ###
  jasmineEnv.specFilter = (spec) ->
    htmlReporter.specFilter spec

  ###
  Run all of the tests
  ###
  jasmineEnv.execute()
