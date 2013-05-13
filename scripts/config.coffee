require.config
  # # Configure Library Locations
  paths:
    # ## Template and Style paths
    templates: '../templates'
    styles: '../styles'
    
    # ## Requirejs plugins
    text: 'libs/require/plugins/text'
    hbs: 'libs/require/plugins/require-handlebars/hbs'

    # ## Core Libraries
    jquery: 'libs/jquery/jquery'
    underscore: 'libs/lodash'
    backbone: 'libs/backbone/backbone'
    # Layout manager for backbone
    marionette: 'libs/backbone/marionette'

    # ## UI Libraries
    aloha: 'libs/aloha-editor/lib/aloha'
    # Bootstrap Plugins
    bootstrapAffix: 'libs/bootstrap/js/bootstrap-affix'
    bootstrapAlert: 'libs/bootstrap/js/bootstrap-alert'
    bootstrapButton: 'libs/bootstrap/js/bootstrap-button'
    bootstrapCarousel: 'libs/bootstrap/js/bootstrap-carousel'
    bootstrapCollapse: 'libs/bootstrap/js/bootstrap-collapse'
    bootstrapDropdown: 'libs/bootstrap/js/bootstrap-dropdown'
    bootstrapModal: 'libs/bootstrap/js/bootstrap-modal'
    bootstrapPopover: 'libs/bootstrap/js/bootstrap-popover'
    bootstrapScrollspy: 'libs/bootstrap/js/bootstrap-scrollspy'
    bootstrapTab: 'libs/bootstrap/js/bootstrap-tab'
    bootstrapTooltip: 'libs/bootstrap/js/bootstrap-tooltip'
    bootstrapTransition: 'libs/bootstrap/js/bootstrap-transition'
    bootstrapTypeahead: 'libs/bootstrap/js/bootstrap-typeahead'

    # ## Handlebars Dependencies
    Handlebars: 'libs/require/plugins/require-handlebars/Handlebars'
    i18nprecompile: 'libs/require/plugins/require-handlebars/hbs/i18nprecompile'
    json2: 'libs/require/plugins/require-handlebars/hbs/json2'


  # # Map prefixes
  map:
    '*':
      css: 'libs/require/plugins/require-css/css'
      less: 'libs/require/plugins/require-less/less'

  # # Shims
  # Used to support libraries that were not written for AMD
  #
  # List the dependencies and what global object is available
  # when the library is done loading (for jQuery plugins this can be `jQuery`)
  shim:

    # ## Core Libraries
    underscore:
      exports: '_'

    backbone:
      deps: ['underscore', 'jquery']
      exports: 'Backbone'

    marionette:
      deps: ['underscore', 'backbone']
      exports: 'Marionette'

    # ## UI Libraries
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


  # Handlebars Requirejs Plugin Configuration
  # This configures `requirejs` plugins (used when loading templates `'hbs!...'`).
  hbs:
    disableI18n: true
    helperPathCallback: (name) ->
      return "cs!../templates/helpers/#{name}"
    templateExtension: 'html'


# # Load and run the application
define ['cs!app'], (app) ->
  app.start();