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

  return Marionette.ItemView.extend
    template: rolesTemplate

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

    setupSelect2: ($el, attr) ->
      $el.val(@model.get(attr).join('|'))

      $el.select2
        tags: @model.get(attr) or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: ajaxHandler(URLS.USERS)

      $el.on 'change', (e) =>
        @model.set(attr, $el.val().split('|'), {silent: true})

      @makeSortable($el)

    onRender: ->
      @setupSelect2(@$el.find('[name=copyright-holders]'), 'copyrightHolders')
      @setupSelect2(@$el.find('[name=authors]'), 'authors')
      @setupSelect2(@$el.find('[name=editors]'), 'editors')
      @setupSelect2(@$el.find('[name=translators]'), 'translators')

      @delegateEvents()

    attrsToSave: () ->
      # Grab the authors from the multiselect input element.
      # They are separated with a `|` character defined when select2 was configured
      authors = (kw for kw in @$el.find('*[name=authors]').val().split('|'))
      copyrightHolders = (kw for kw in @$el.find('*[name=copyrightHolders]').val().split('|'))

      return {
        authors: authors
        copyrightHolders: copyrightHolders
      }
