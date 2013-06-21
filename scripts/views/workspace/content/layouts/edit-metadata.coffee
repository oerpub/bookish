define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!configs/app'
  'cs!models/languages'
  'cs!views/workspace/content/edit-summary'
  'hbs!templates/workspace/content/layouts/edit-metadata'
  'hbs!templates/workspace/content/language-variants'
  'i18n!nls/strings'
  'select2'
  'bootstrapCollapse'
], ($, _, Backbone, Marionette, config, languagesModel, SummaryView, metadataTemplate, languagesTemplate, __) ->

  # Given the language list in [languages.coffee](languages.html)
  # this reorganizes them so they can be shown in a dropdown.
  languages = [{code: '', native: '', english: ''}]
  for languageCode, value of languagesModel.getLanguages()
    value = $.extend({}, value)  # Clone the value.
    $.extend(value, {code: languageCode})
    languages.push(value)

  return Marionette.Layout.extend
    template: metadataTemplate

    regions:
      summary: '.summary'

    onRender: () ->
      @summary.show(new SummaryView({model: @model}))

      @setupSelect2(@$el.find('[name=subjects]'), 'subjects', config.get('metadataSubjects'))
      @setupSelect2(@$el.find('[name=keywords]'), 'keywords')
      @setupSelect2(@$el.find('[name=googleTrackingID]'), 'googleTrackingID')

      # Populate the Language dropdown and Subjects checkboxes
      $languages = @$el.find('[name=language]')
      for lang in languages
        $lang = $('<option></option>').attr('value', lang.code).text(lang.native)
        $languages.append($lang)

      $languages.select2
        placeholder: __('Select a language')

      # Select the correct language (Handlebars can't do that)
      @_updateLanguage()

      @delegateEvents()

    events:
      'change [name=language]': '_updateLanguageVariant'

    # Make a multiselect widget sortable using jQueryUI.
    # Unfortunately jQueryUI is not available until Aloha finishes loading
    # so postpone making it sortable until `Aloha.ready`
    makeSortable: ($el) ->
      Aloha.ready ->
        $el.select2('container')
        .find('ul.select2-choices')
        .sortable
          cursor: 'move'
          containment: 'parent'
          start: ->  $el.select2 'onSortStart'
          update: -> $el.select2 'onSortEnd'

    setupSelect2: ($el, attr, tags) ->
      $el.select2
        tags: tags or @model.get(attr) or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)

      $el.select2('val', @model.get(attr))

      $el.on 'change', (e) =>
        @model.set(attr, $el.val().split('|'), {silent: true})

      @makeSortable($el)

    # Update the UI when the language changes.
    # Also called during initial render
    _updateLanguage: () ->
      language = @model.get('language') or ''
      [lang] = language.split('-')
      @$el.find("[name=language]").select2('val', lang)
      @_updateLanguageVariant()

    _updateLanguageVariant: () ->
      $language = @$el.find('[name=language]')
      language = @model.get('language') or ''
      [lang, variant] = language.split('-')
      if $language.val() isnt lang
        lang = $language.val()
        variant = null
      $variant = @$el.find('[name=variantLanguage]')
      $label = @$el.find('[for=variantLanguage]')
      variants = []
      for code, value of languagesModel.getCombined()
        if code[..1] is lang
          $.extend(value, {code: code})
          variants.push(value)
      if variants.length > 0
        # Generate the language variants dropdown.
        $variant.removeAttr('disabled')
        $variant.html(languagesTemplate({'variants': variants}))
        $variant.find("option[value=#{language}]").attr('selected', true)
        $label.removeClass('hidden')
        $variant.removeClass('hidden')
      else
        $variant.empty().attr('disabled', true)
        $variant.addClass('hidden')
        $label.addClass('hidden')