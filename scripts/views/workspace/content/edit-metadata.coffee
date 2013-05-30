define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'cs!configs/app'
  'cs!models/languages'
  'hbs!templates/workspace/content/edit-metadata'
  'hbs!templates/workspace/content/language-variants'
  'i18n!nls/strings'
  'select2'
], ($, _, Backbone, Marionette, config, languagesModel, metadataTemplate, languagesTemplate, __) ->

  # Given the language list in [languages.coffee](languages.html)
  # this reorganizes them so they can be shown in a dropdown.
  languages = [{code: '', native: '', english: ''}]
  for languageCode, value of languagesModel.getLanguages()
    value = $.extend({}, value)  # Clone the value.
    $.extend(value, {code: languageCode})
    languages.push(value)

  return Marionette.ItemView.extend
    template: metadataTemplate

    # Bind methods onto jQuery events that happen in the view
    events:
      'change *[name=language]': '_updateLanguageVariant'

    initialize: () ->
      console.log @model
      #@listenTo @model, 'change:language', => @_updateLanguage()
      #@listenTo @model, 'change:subjects', => @_updateSubjects()
      #@listenTo @model, 'change:keywords', => @_updateKeywords()

    # Update the UI when the language changes.
    # Also called during initial render
    _updateLanguage: () ->
      language = @model.get('language') or ''
      [lang] = language.split('-')
      @$el.find("*[name=language]").select2('val', lang)
      @_updateLanguageVariant()

    _updateLanguageVariant: () ->
      $language = @$el.find('*[name=language]')
      language = @model.get('language') or ''
      [lang, variant] = language.split('-')
      if $language.val() != lang
        lang = $language.val()
        variant = null
      $variant = @$el.find('*[name=variantLanguage]')
      $label = @$el.find('*[for=variantLanguage]')
      variants = []
      for code, value of languagesModel.getCombined()
        if code[..1] == lang
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

    # Helper method to populate a multiselect input
    _updateSelect2: (key) ->
      @$el.find("*[name=#{key}]").select2('val', @model.get key)

    # Update the View with new subjects selected
    _updateSubjects: -> @_updateSelect2 'subjects'

    # Update the View with new keywords selected
    _updateKeywords: -> @_updateSelect2 'keywords'

    # Populate some of the dropdowns like language and subjects.
    # Also, initialize the select2 widget on elements
    onRender: () ->
      # Populate the Language dropdown and Subjects checkboxes
      $languages = @$el.find('*[name=language]')
      for lang in languages
        $lang = $('<option></option>').attr('value', lang.code).text(lang.native)
        $languages.append($lang)

      $languages.select2
        placeholder: __('Select a language')

      $subjects = @$el.find('*[name=subjects]')
      $subjects.select2
        tags: config.get('metadataSubjects')
        tokenSeparators: [',']
        separator: '|' # String used to delimit ids in $('input').val()

      # Enable multiselect on certain elements
      $keywords = @$el.find('*[name=keywords]')
      $keywords.select2
        tags: @model.get('keywords') or []
        tokenSeparators: [',']
        separator: '|' # String used to delimit ids in $('input').val()
        #ajax: SELECT2_AJAX_HANDLER(URLS.KEYWORDS)
        initSelection: (element, callback) ->
          data = []
          _.each element.val().split('|'), (str) -> data.push {id: str, text: str}
          callback(data)

      # Select the correct language (Handlebars can't do that)
      @_updateLanguage()
      @_updateSubjects()
      @_updateKeywords()

      @delegateEvents()

    # This is used by `DialogWrapper` which offers a "Save" and "Cancel" buttons
    attrsToSave: () ->
      language = @$el.find('*[name=language]').val()
      variant = @$el.find('*[name=variantLanguage]').val()
      language = variant or language
      # subjects could be the empty string in which case it would be set to `[""]`
      subjects = (kw for kw in @$el.find('*[name=subjects]').val().split('|'))
      subjects = [] if '' is subjects[0]
      # Keywords could be the empty string in which case it would be set to `[""]`
      keywords = (kw for kw in @$el.find('*[name=keywords]').val().split('|'))
      keywords = [] if '' is keywords[0]

      return {
        language: language
        subjects: subjects
        keywords: keywords
      }