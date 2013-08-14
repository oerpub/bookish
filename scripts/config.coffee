BOWER = '../bower_components' # The path to the downloaded bower components

require.config
  # # Configure Library Locations
  paths:

    # Change some of the models for the Application to use github and EPUB
    app: 'gh-book/app'
    github: "#{BOWER}/octokit/octokit"
    'collections/content': 'gh-book/content'
    'views/workspace/menu/auth': 'gh-book/auth'
    session: 'gh-book/session'
    jsSHA: "#{BOWER}/jsSHA/src/sha_dev" # Calculate the sha1 hash for resources


    # ## Template and Style paths
    templates: '../templates'
    styles: '../styles'

    # ## Requirejs plugins
    text: "#{BOWER}/requirejs-text/text"
    json: "#{BOWER}/requirejs-plugins/src/json"
    i18n: 'helpers/i18n-custom'
    hbs: "#{BOWER}/require-handlebars-plugin/hbs"

    # ## Core Libraries
    jquery: "#{BOWER}/jquery/jquery"
    underscore: "#{BOWER}/lodash/lodash"
    backbone: "#{BOWER}/backbone/backbone"
    # Layout manager for backbone
    marionette: "#{BOWER}/backbone.marionette/lib/backbone.marionette"

    # ## UI Libraries
    aloha: "#{BOWER}/aloha-editor/src/lib/aloha"
    select2: "#{BOWER}/select2/select2"
    moment: "#{BOWER}/moment/moment"
    # Bootstrap Plugins
    bootstrapAffix: "#{BOWER}/bootstrap/js/bootstrap-affix"
    bootstrapAlert: "#{BOWER}/bootstrap/js/bootstrap-alert"
    bootstrapButton: "#{BOWER}/bootstrap/js/bootstrap-button"
    bootstrapCarousel: "#{BOWER}/bootstrap/js/bootstrap-carousel"
    bootstrapCollapse: "#{BOWER}/bootstrap/js/bootstrap-collapse"
    bootstrapDropdown: "#{BOWER}/bootstrap/js/bootstrap-dropdown"
    bootstrapModal: "#{BOWER}/bootstrap/js/bootstrap-modal"
    bootstrapPopover: "#{BOWER}/bootstrap/js/bootstrap-popover"
    bootstrapScrollspy: "#{BOWER}/bootstrap/js/bootstrap-scrollspy"
    bootstrapTab: "#{BOWER}/bootstrap/js/bootstrap-tab"
    bootstrapTooltip: "#{BOWER}/bootstrap/js/bootstrap-tooltip"
    bootstrapTransition: "#{BOWER}/bootstrap/js/bootstrap-transition"
    bootstrapTypeahead: "#{BOWER}/bootstrap/js/bootstrap-typeahead"

    # ## Handlebars Dependencies
    Handlebars: "#{BOWER}/require-handlebars-plugin/Handlebars"
    i18nprecompile: "#{BOWER}/require-handlebars-plugin/hbs/i18nprecompile"
    json2: "#{BOWER}/require-handlebars-plugin/hbs/json2"


  # # Map prefixes
  map:
    '*':
      css: "#{BOWER}/require-css/css"
      less: "#{BOWER}/require-less/less"

  # # Shims
  # Used to support libraries that were not written for AMD
  #
  # List the dependencies and what global object is available
  # when the library is done loading (for jQuery plugins this can be `jQuery`)
  shim:

    # jsSHA does not use requirejs so use the global
    jsSHA:
      exports: 'jsSHA'

    # ## Core Libraries
    underscore:
      exports: '_'

    backbone:
      deps: ['underscore', 'jquery']
      exports: 'Backbone'

    marionette:
      # Load the Backbone Logger before Marionette, since Marionette clones `Backbone.Events`.
      # Waiting until after Marionette loads requires modifying every single Marionette component,
      # or nearly all of them (as they nearly all individually clone `Backbone.Events`).
      deps: ['underscore', 'backbone', 'cs!helpers/logger']
      exports: 'Marionette'

    # ## UI Libraries
    # Bootstrap Plugins
    bootstrapAffix: ['jquery']
    bootstrapAlert: ['jquery']
    bootstrapButton: ['jquery']
    bootstrapCarousel: ['jquery']
    bootstrapCollapse: ['jquery']
    bootstrapDropdown: ['jquery']
    bootstrapModal: ['jquery', 'bootstrapTransition']
    bootstrapPopover: ['jquery', 'bootstrapTooltip']
    bootstrapScrollspy: ['jquery']
    bootstrapTab: ['jquery']
    bootstrapTooltip: ['jquery']
    bootstrapTransition: ['jquery']
    bootstrapTypeahead: ['jquery']

    # Select2
    select2:
      deps: ['jquery', 'css!./select2']
      exports: 'Select2'

    aloha:
      deps: ['jquery', 'bootstrapModal', 'bootstrapPopover', 'cs!configs/aloha', 'cs!configs/mathjax']
      exports: 'Aloha'
      init: ($, alohaConfig, mathjaxConfig) ->
        script = document.createElement("script")
        script.src = "http://cdn.mathjax.org/mathjax/2.0-latest/MathJax.js?config=TeX-MML-AM_HTMLorMML-full&amp;delayStartupUntil=configured"
        script.text = 'MathJax.Hub.Config(' + JSON.stringify(mathjaxConfig) + ');' + 'MathJax.Hub.Startup.onload();'

        document.getElementsByTagName("head")[0].appendChild(script);

        jQuery.browser.version = 10000 # Hack to fix aloha-editor's version checking

        return Aloha

  # Handlebars Requirejs Plugin Configuration
  # This configures `requirejs` plugins (used when loading templates `'hbs!...'`).
  hbs:
    disableI18n: true
    helperPathCallback: (name) ->
      return "cs!../templates/helpers/#{name}"
    templateExtension: 'html'

  waitSeconds: 42

# # Load and run the application
define ['cs!app'], (app) ->
  app.start()
