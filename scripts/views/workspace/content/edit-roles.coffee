define [
  'jquery'
  'underscore'
  'backbone'
  'marionette'
  'aloha'
  'hbs!templates/workspace/content/edit-roles'
  'select2'
  'bootstrapCollapse'
], ($, _, Backbone, Marionette, Aloha, rolesTemplate) ->

  # Select2 is a multiselect UI library.
  # It queries the webserver to provide search results as you type
  #
  # Given a `url` to query (like `/users` or `/keywords`) this returns a config
  # used when binding select2 to an input.
  ###
  ajaxHandler = (url) ->
    quietMillis: 500
    url: url
    dataType: 'json'
    data: (term, page) ->
      q: term # search term
    # parse the results into the format expected by Select2
    results: (data, page) ->
      return {
        results: ({id:id, text:id} for id in data)
      }
  ###

  # Make a multiselect widget sortable using jQueryUI.
  # Unfortunately jQueryUI is not available until Aloha finishes loading
  # so postpone making it sortable until `Aloha.ready`
  makeSortable = ($el) ->
    Aloha.ready ->
      $el.select2('container')
      .find('ul.select2-choices')
      .sortable
        cursor: 'move'
        containment: 'parent'
        start: ->  $el.select2 'onSortStart'
        update: -> $el.select2 'onSortEnd'

  return Marionette.ItemView.extend
    template: rolesTemplate

    onRender: ->
      $copyrightHolders = @$el.find('[name=copyright-holders]')
      $authors = @$el.find('[name=authors]')
      $editors = @$el.find('[name=editors]')
      $translators = @$el.find('[name=translators]')

      $copyrightHolders.select2
        tags: @model.get('copyrightHolders') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)
      $authors.select2
        # **FIXME:** The authors should be looked up instead of being arbitrary text
        tags: @model.get('authors') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)
      $editors.select2
        tags: @model.get('editors') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)
      $translators.select2
        tags: @model.get('translators') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)

      makeSortable($authors)
      makeSortable($copyrightHolders)

      # Populate the multiselect widgets with data from the backbone model
      @_updateAuthors()
      @_updateCopyrightHolders()

      @delegateEvents()

    _updateAuthors: -> @$el.find('*[name=authors]').select2 'val', (@model.get('authors') or [])
    _updateCopyrightHolders: -> @$el.find('*[name=copyrightHolders]').select2 'val', (@model.get('copyrightHolders') or [])

    attrsToSave: () ->
      # Grab the authors from the multiselect input element.
      # They are separated with a `|` character defined when select2 was configured
      authors = (kw for kw in @$el.find('*[name=authors]').val().split('|'))
      copyrightHolders = (kw for kw in @$el.find('*[name=copyrightHolders]').val().split('|'))

      return {
        authors: authors
        copyrightHolders: copyrightHolders
      }
