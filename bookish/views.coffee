# Backbone Views
# =======
# Most views have the following properties:
#
# 1. Load a Handlebar template using the `hbs` plugin (see `define` below)
# 2. Attach listeners to the corresponding model (see `initialize` method and `events:`)
# 3. Attach jQuery listeners to the rendered template (see `onRender` methods)
# 4. Navigate to a different "page" (see `Controller.*` in the `jQuery.on` handlers)

#
define [
  'exports'
  'underscore'
  'backbone'
  'marionette'
  'jquery'
  'aloha'
  'moment' # For generating relative times
  'bookish/controller'
  'bookish/models'
  'bookish/media-types'
  './languages'
  # Load the Handlebar templates
  'hbs!bookish/views/content-edit'
  'hbs!bookish/views/search-box'
  'hbs!bookish/views/search-results'
  'hbs!bookish/views/search-results-item'
  'hbs!bookish/views/dnd-handle'
  'hbs!bookish/views/modal-wrapper'
  'hbs!bookish/views/edit-metadata'
  'hbs!bookish/views/edit-roles'
  'hbs!bookish/views/language-variants'
  'hbs!bookish/views/aloha-toolbar'
  'hbs!bookish/views/sign-in-out'
  'hbs!bookish/views/add'
  'hbs!bookish/views/add-item'
  'hbs!bookish/views/book-edit'
  'hbs!bookish/views/book-edit-node'
  # Load internationalized strings
  'i18n!bookish/nls/strings'
  # `bootstrap` and `select2` add to jQuery and don't export anything of their own
  # so they are 'defined' _after_ everything else
  'bootstrap'
  'select2'
  # Include CSS icons used by the toolbar
  'css!font-awesome'
  # Include the main CSS file
  'less!bookish'
], (exports, _, Backbone, Marionette, jQuery, Aloha, Moment, Controller, Models, MEDIA_TYPES, Languages, CONTENT_EDIT, SEARCH_BOX, SEARCH_RESULT, SEARCH_RESULT_ITEM, DND_HANDLE, DIALOG_WRAPPER, EDIT_METADATA, EDIT_ROLES, LANGUAGE_VARIANTS, ALOHA_TOOLBAR, SIGN_IN_OUT, ADD_VIEW, ADD_ITEM_VIEW, BOOK_EDIT, BOOK_EDIT_NODE, __) ->


  # Drag and Drop Behavior
  # -------
  #
  # Several views allow content to be dragged around.
  # Each item that is draggable **must** contain 3 DOM attributes:
  #
  # - `data-content-id`:    The unique id of the piece of content (it can be a path)
  # - `data-media-type`:    The mime-type of the content being dragged
  # - `data-content-title`: A  human-readable title for the content
  #
  # In addition it may contain the following attributes:
  #
  # - `data-drag-operation="copy"`: Specifies the CSS to add a "+" when dragging
  #                                 hinting that the element will not be removed.
  #                                 (For example, content in a search result)
  #
  # Additionally, each draggable element should not contain any text children
  # so CSS can hide children and properly style the cloned element that is being dragged.
  _EnableContentDragging = (model, $el) ->
    $el.data 'editor-model', model
    $el.draggable
      addClasses: false
      revert: 'invalid'
      # Ensure the handle is on top (zindex) and not bound to be constrained inside a div visually
      appendTo: 'body'
      # Place the little handle right next to the mouse
      cursorAt:
        top: 0
        left: 0
      helper: (evt) ->
        title = model.get('title') or model.dereference().get('title') or ''
        shortTitle = title
        shortTitle = title.substring(0, 20) + '...' if title.length > 20

        # If the content is a pointer to a piece of content (`BookTocNode`)
        # then use the actual content's mediaType
        mediaType = model.dereference().mediaType

        # Generate the handle div using a template
        $handle = jQuery DND_HANDLE
          id: model.id
          mediaType: mediaType
          title: title
          shortTitle: shortTitle
        return $handle


  # **FIXME:** Move this delay into a common module so the mock AJAX code can use them too
  DELAY_BEFORE_SAVING = 3000

  # Updates the relative time for a set of elements periodically
  updateTimes = ($times) ->
    $times.each (i, el) =>
      $el = jQuery(el)
      updateTime = =>
        # If the element is detached from the DOM don't continue updating it
        if $el.parents('html')[0]
          # Generate a relative time and set it as the text of the `time` element
          utc = $el.attr 'datetime'
          if utc
            utcTime = Moment.utc(utc)
            now = Moment()
            diff = now.diff(utcTime) / 1000 # Put it in Seconds instead of milliseconds
            # If the update was in the future then change it to be `a few seconds ago`
            utcTime = now if diff < 0

            # Set the human-readable text for the time
            $el.text utcTime.fromNow() # Passing `true` would drop the suffix
            nextUpdate = 10
            if diff < 60
              nextUpdate = 5       # update in 5 seconds
            else if diff < 60 * 60
              nextUpdate = 30      # update in 30 seconds
            else
              nextUpdate = 60 * 2  # update in 2 minutes
            setTimeout updateTime, (nextUpdate * 1000)
      updateTime()


  # Select2 is a multiselect UI library.
  # It queries the webserver to provide search results as you type
  #
  # Given a `url` to query (like `/users` or `/keywords`) this returns a config
  # used when binding select2 to an input.
  SELECT2_AJAX_HANDLER = (url) ->
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

  # Make a multiselect widget sortable using jQueryUI.
  # Unfortunately jQueryUI is not available until Aloha finishes loading
  # so postpone making it sortable until `Aloha.ready`
  SELECT2_MAKE_SORTABLE = ($el) ->
    Aloha.ready ->
      $el.select2('container')
      .find('ul.select2-choices')
      .sortable
        cursor: 'move'
        containment: 'parent'
        start: ->  $el.select2 'onSortStart'
        update: -> $el.select2 'onSortEnd'


  # **FIXME:** Move these subjects to a common module so the mock code can use them and can be used elsewhere
  METADATA_SUBJECTS = ['Arts', 'Mathematics and Statistics', 'Business',
    'Science and Technology', 'Humanities', 'Social Sciences']

  # Given the language list in [languages.coffee](languages.html)
  # this reorganizes them so they can be shown in a dropdown.
  LANGUAGES = [{code: '', native: '', english: ''}]
  for languageCode, value of Languages.getLanguages()
    value = jQuery.extend({}, value)  # Clone the value.
    jQuery.extend(value, {code: languageCode})
    LANGUAGES.push(value)


  # Search Result Views (workspace)
  # -------
  #
  # A list of search results (stubs of models only containing an icon, url, title)
  # need a generic view for an item.
  #
  # Since we don't really distinguish between a search result view and a workspace/collection/etc
  # just consider them the same.
  exports.SearchResultsItemView = Marionette.ItemView.extend
    tagName: 'tr'
    template: SEARCH_RESULT_ITEM
    initialize: ->
      @listenTo @model, 'change', => @render()
    onRender: ->
      # Render the modified time in a relative format and update it periodically
      $times = @$el.find('time[datetime]')
      updateTimes $times

      @$el.on 'click', => Controller.editModel(@model)
      # Add DnD options to content
      $content = @$el.children('*[data-media-type]')

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>

        _EnableContentDragging(@model, $content)

        # Figure out which mediaTypes can be dropped onto each element
        $content.each (i, el) =>
          $el = jQuery(el)

          ModelType = MEDIA_TYPES.get @model.mediaType
          validSelectors = _.map ModelType::accepts(), (mediaType) -> "*[data-media-type=\"#{mediaType}\"]"
          validSelectors = validSelectors.join ','

          if validSelectors
            $el.droppable
              greedy: true
              addClasses: false
              accept: validSelectors
              activeClass: 'editor-drop-zone-active'
              hoverClass: 'editor-drop-zone-hover'
              drop: (evt, ui) =>
                $drag = ui.draggable
                $drop = jQuery(evt.target)

                # Find the model representing the id that was dragged
                model = $drag.data 'editor-model'
                drop = $drop.data 'editor-model'
                # Sanity-check before dropping:
                # Dereference if this is a pointer
                if drop.accepts().indexOf(model.mediaType) < 0
                  model = model.dereference()
                throw 'INVALID_DROP_MEDIA_TYPE' if drop.accepts().indexOf(model.mediaType) < 0

                # Delay the call so jQuery.droppable has time to clean up before the DOM changes
                delay = => drop.addChild model
                setTimeout delay, 10


  # This can also be thought of as the Workspace view
  exports.SearchResultsView = Marionette.CompositeView.extend
    template: SEARCH_RESULT
    itemViewContainer: 'tbody'
    itemView: exports.SearchResultsItemView

  # The search box. Changing the text will cause the underlying collection to filter
  # and fire off `add/remove` events.
  exports.SearchBoxView = Marionette.ItemView.extend
    template: SEARCH_BOX
    events:
      'keyup #search': 'setFilter'
      'change #search': 'setFilter'
    initialize: ->
      throw 'BUG: You must wrap the collection in a FilterableCollection' if not @model.setFilter
    setFilter: (evt) ->
      $searchBox = jQuery(@$el).find '#search'
      filterStr = $searchBox.val()
      filterStr = '' if filterStr.length < 2
      @model.setFilter filterStr


  # A generic way of editing a HTML key in a model using the Aloha Editor
  exports.AlohaEditView = Marionette.ItemView.extend
    # **NOTE:** This template is not wrapped in an element
    template: () -> throw 'You need to specify a template, modelKey, and optionally alohaOptions'
    modelKey: null
    alohaOptions: null

    initialize: ->

      # Update the view when the content is done loading (remove progress bar)
      @listenTo @model, 'change:_done', (model, value, options) => @render()

      @listenTo @model, "change:#{@modelKey}", (model, value, options) =>
        return if options.internalAlohaUpdate

        alohaId = @$el.attr('id')
        # Sometimes Aloha hasn't loaded up yet
        if alohaId and @$el.parents()[0]
          alohaEditable = Aloha.getEditableById(alohaId)
          editableBody = alohaEditable.getContents()
          alohaEditable.setContents(value) if value != editableBody
        else
          @$el.empty().append(value)

    onRender: ->
      # Wait until Aloha is started before loading MathJax.
      MathJax?.Hub.Configured()

      if @model.get '_done'
        # Once Aloha has finished loading enable
        @$el.addClass('disabled')
        Aloha.ready =>
          @$el.aloha(@alohaOptions)
          @$el.removeClass('disabled')

        # Auto save after the user has stopped making changes
        updateModelAndSave = =>
          alohaId = @$el.attr('id')
          # Sometimes Aloha hasn't loaded up yet
          # Only save when the editable has changed
          if alohaId
            alohaEditable = Aloha.getEditableById(alohaId)
            editableBody = alohaEditable.getContents()
            # Change the contents but do not update the Aloha editable area
            @model.set @modelKey, editableBody, {internalAlohaUpdate: true}

        # Grr, the `aloha-smart-content-changed` can only be listened to globally
        # (via `Aloha.bind`) instead of on each editable.
        #
        # This is problematic when we have multiple Aloha editors on a page.
        # Instead, autosave after some period of inactivity.
        @$el.on 'blur', updateModelAndSave



  # Edit Content Body
  # -------
  exports.ContentEditView = exports.AlohaEditView.extend
    # **NOTE:** This template is not wrapped in an element
    template: CONTENT_EDIT
    modelKey: 'body'

  # Edit the title field of a piece of Content
  exports.TitleEditView = exports.AlohaEditView.extend
    # **NOTE:** This template is not wrapped in an element
    template: (serialized_model) -> "#{serialized_model.title or 'Untitled'}"
    modelKey: 'title'
    tagName: 'span' # override the default tagName of `div` so titles can be edited inline.


  # Parse in (from handlebars) the Aloha Toolbar and buttons
  exports.ContentToolbarView = Marionette.ItemView.extend
    template: ALOHA_TOOLBAR

    onRender: ->
      # Wait until Aloha is started before enabling the toolbar
      @$el.addClass('disabled')
      Aloha.ready =>
        @$el.removeClass('disabled')

  # Content Metadata
  # -------

  exports.MetadataEditView = Marionette.ItemView.extend
    template: EDIT_METADATA

    # Bind methods onto jQuery events that happen in the view
    events:
      'change *[name=language]': '_updateLanguageVariant'

    initialize: ->
      @listenTo @model, 'change:language', => @_updateLanguage()
      @listenTo @model, 'change:subjects', => @_updateSubjects()
      @listenTo @model, 'change:keywords', => @_updateKeywords()

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
      for code, value of Languages.getCombined()
        if code[..1] == lang
          jQuery.extend(value, {code: code})
          variants.push(value)
      if variants.length > 0
        # Generate the language variants dropdown.
        $variant.removeAttr('disabled')
        $variant.html(LANGUAGE_VARIANTS('variants': variants))
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
    onRender: ->
      # Populate the Language dropdown and Subjects checkboxes
      $languages = @$el.find('*[name=language]')
      for lang in LANGUAGES
        $lang = jQuery('<option></option>').attr('value', lang.code).text(lang.native)
        $languages.append($lang)

      $languages.select2
        placeholder: __('Select a language')

      $subjects = @$el.find('*[name=subjects]')
      $subjects.select2
        tags: METADATA_SUBJECTS
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


  exports.RolesEditView = Marionette.ItemView.extend
    template: EDIT_ROLES

    onRender: ->
      $authors = @$el.find('*[name=authors]')
      $copyrightHolders = @$el.find('*[name=copyrightHolders]')

      $authors.select2
        # **FIXME:** The authors should be looked up instead of being arbitrary text
        tags: @model.get('authors') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: SELECT2_AJAX_HANDLER(URLS.USERS)
      $copyrightHolders.select2
        tags: @model.get('copyrightHolders') or []
        tokenSeparators: [',']
        separator: '|'
        #ajax: SELECT2_AJAX_HANDLER(URLS.USERS)

      SELECT2_MAKE_SORTABLE $authors
      SELECT2_MAKE_SORTABLE $copyrightHolders

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



  # Dialog Wrapper
  # -------
  # This class wraps a view in a div and only causes changes when
  # the 'Save' button is clicked.
  #
  # Looks like phil came to the same conclusion as the author of Marionette
  # (Don't make a Bootstrap Modal in a `Backbone.View`):
  # [http://lostechies.com/derickbailey/2012/04/17/managing-a-modal-dialog-with-backbone-and-marionette/]
  exports.DialogWrapper = Marionette.ItemView.extend
    template: DIALOG_WRAPPER
    onRender: ->
      @options.view.render()
      @$el.find('.dialog-body').append @options.view.$el

      # Fire a cancel event when the cancel button is pressed
      @$el.on 'click', '.cancel', => @trigger 'cancelled'

      # Trigger the `model.save` when the save button is clicked
      # using the attributes from `@options.view.attrsToSave()`
      @$el.on 'click', '.save', (evt) =>
        evt.preventDefault()
        attrs = @options.view.attrsToSave()

        @options.view.model.save attrs,
          success: (res) =>
            # Trigger a 'sync' because if 'success' is provided 'sync' is not triggered
            @options.view.model.trigger('sync')
            @trigger 'saved'

          error: (res) =>
            alert('Something went wrong when saving: ' + res)


  # Default Auth View
  # -------
  # The top-right of each page should have either:
  #
  # 1. a Sign-up/Login link if not logged in
  # 2. a logoff link with the current user name if logged in
  #
  # This view updates when the login state changes
  exports.AuthView = Marionette.ItemView.extend
    template: SIGN_IN_OUT
    events:
      'click #sign-in':       'signIn'
      'click #sign-out':      'signOut'
      'click #save-content':  'saveContent'

    initialize: ->
      @dirtyModels = new Backbone.Collection()
      # Sort by `id` so new models are saved first.
      # This way their id's change and their references (in books and Folders)
      # will be updated before the Book/Folder is saved.
      @dirtyModels.comparator = 'id'

      # Bind a function to the window if the user tries to navigate away from this page
      beforeUnload = =>
        return 'You have unsaved changes. Are you sure you want to leave this page?' if @hasChanged
      jQuery(window).on 'beforeunload', beforeUnload

      @listenTo @model, 'change', => @render()
      @listenTo @model, 'change:userid', => @render()

      # Listen to all changes made on Content so we can update the save button
      @listenTo Models.ALL_CONTENT, 'change:_isDirty', (model, b,c) =>
        # Figure out if the model was just fetched (all the changed attributes used to be 'undefined')
        # or if the attributes did actually change
        if model.get('_isDirty')
          @dirtyModels.add model
        else
          @dirtyModels.remove model

      @listenTo Models.ALL_CONTENT, 'change:treeNode add:treeNode remove:treeNode', (model, b,c) =>
        @dirtyModels.add model

      @listenTo Models.ALL_CONTENT, 'add', (model) => @dirtyModels.add model if model.get('_isDirty')

      @listenTo @dirtyModels, 'add reset', (model, b,c) =>
        @hasChanged = true
        $save = @$el.find '#save-content'
        $save.removeClass('disabled')
        $save.addClass('btn-primary')

      @listenTo @dirtyModels, 'remove', (model, b,c) =>
        if @dirtyModels.length == 0
          @hasChanged = false
          $save = @$el.find '#save-content'
          $save.addClass('disabled')
          $save.removeClass('btn-primary')

    onRender: ->
      # Enable tooltips
      @$el.find('*[title]').tooltip()

    signIn: ->
      # The browser will go to the login page because `#sign-in` is a link

    # Clicking on the link will redirect to the logoff page
    # Before it does, update the model
    signOut: -> @model.signOut()

    # Save each model in sequence.
    # **FIXME:** This should be done in a commit batch
    saveContent: ->
      return alert 'You need to Sign In (and make sure you can edit) before you can save changes' if not @model.get 'id'
      $save = @$el.find('#save-progress-modal')
      $saving     = $save.find('.saving')
      $alertError = $save.find('.alert-error')
      $successBar = $save.find('.progress > .bar.success')
      $errorBar   = $save.find('.progress > .bar.error')
      $label = $save.find('.label')

      total = @dirtyModels.length
      errorCount = 0
      finished = false

      recSave = =>
        $successBar.width(((total - @dirtyModels.length - errorCount) * 100 / total) + '%')
        $errorBar.width((  errorCount                                 * 100 / total) + '%')

        if @dirtyModels.length == 0
          if errorCount == 0
            finished = true
            $save.modal('hide')
          else
            $alertError.removeClass 'hide'

        else
          model = @dirtyModels.first()
          $label.text(model.get('title'))

          # Clear the changed bit since it is saved.
          #     delete model.changed
          #     saving = true; recSave()
          saving = model.save null,
              success: =>
                # Clear the dirty bit for the model
                model.set {_isDirty:false}
                recSave()
              error: -> errorCount += 1
          if not saving
            console.log "Skipping #{model.id} because it is not valid"
            recSave()

      $alertError.addClass('hide')
      $saving.removeClass('hide')
      $save.modal('show')
      recSave()

      # Only show the 'Saving...' alert box if the save takes longer than 5 seconds
      setTimeout(->
        if total and (not finished or errorCount)
          $save.modal('show')
          $alertError.removeClass('hide')
          $saving.addClass('hide')
      , 2000)

  AddItemView = Marionette.ItemView.extend
    template: ADD_ITEM_VIEW
    tagName: 'li'
    events:
      'click button': 'addItem'

    addItem: ->
      ContentType = @model.get('modelType')
      content = new ContentType()
      Models.WORKSPACE.add content
      @options.addToContext?(content)

      # Begin editing an item as soon as it is added.
      # Some content (like Books and Folders) do not have an `editAction`
      content.editAction?()

  exports.AddView = Marionette.CompositeView.extend
    template: ADD_VIEW
    itemView: AddItemView
    itemViewContainer: '.btn-group > ul'
    tagName: 'span'


  # Book Editing
  # -------
  # The book editor has a tree of node views (nested `Marionette.ContainerView`)
  # with Drag and Drop handling restricted by `mediaType`.

  BookEditNodeView = Marionette.CompositeView.extend
    template: BOOK_EDIT_NODE
    tagName: 'li'
    itemViewContainer: '> ol'
    events:
      # The `.editor-node-body` is needed because `li` elements render differently
      # when there is a space between `<li>` and the first child.
      # `.editor-node-body` ensures there is never a space.
      'click > .editor-node-body > .editor-expand-collapse': 'toggleExpanded'
      'click > .editor-node-body > .no-edit-action': 'toggleExpanded'
      'click > .editor-node-body > .edit-action': 'editAction'
      'click > .editor-node-body > .edit-settings': 'editSettings'

    # Toggle expanded/collapsed in the View
    # -------
    #
    # The first time a node is rendered it is collapsed so we lazily load the
    # `ItemView` children.
    #
    # Initially, the node is collapsed and the following occurs:
    #
    # 1. `@render()` calls `@_renderChildren()`
    # 2. Since `@isExpanded == false` the children are not rendered
    #
    # When the node is expanded:
    #
    # 1. `@isExpanded` is set to `true`
    # 2. `@render()` is called and calls `@_renderChildren()`
    # 3. Since `@isExpanded == true` the children are rendered and attached to the DOM
    # 4. `@hasRendered` is set to `true` so we know not to generate the children again
    #
    #
    # When an expanded node is collapsed:
    #
    # 1. `@isExpanded` is set to `false`
    # 2. A CSS class is set on the `<li>` item to hide children
    # 3. CSS rules hide the children and change the expand/collapse icon
    #
    # When a node that was expanded and collapsed is re-expanded:
    #
    # 1. `@isExpanded` is set to `true`
    # 2. Since `@hasRendered == true` there is no need to call `@render()`
    # 3. The CSS class is removed to show the children again

    isExpanded: false
    hasRendered: false

    # Called from UI when user clicks the collapse/expando buttons
    toggleExpanded: -> @expand !@isExpanded

    # Pass in `false` to collapse
    expand: (@isExpanded) ->
      @$el.toggleClass 'editor-node-expanded', @isExpanded
      # (re)render the model and children if the node is expanded
      # and has not been rendered yet.
      if @isExpanded and !@hasRendered
        @render()

    # From `Marionette.CompositeView`.
    # Added check to only render when the model `@isExpanded`
    _renderChildren: ->
      if @isRendered
        if @isExpanded
          Marionette.CollectionView.prototype._renderChildren.call(@)
          this.triggerMethod('composite:collection:rendered')
        # Remember that the children have been rendered already
        @hasRendered = @isExpanded


    # Perform the edit action and then expand the node to show children.
    editAction: -> @model.editAction(); @expand(true)

    editSettings: ->
      if @model != @model.dereference()
        contentModel = @model.dereference()
        originalTitle = contentModel?.get('title') or @model.get 'title'
        newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', originalTitle
        if '-' == newTitle
          @model.parent?.children()?.remove @model
        else if newTitle == contentModel?.get('title')
          @model.unset 'title'
        else if newTitle
          @model.set 'title', newTitle
      else
        originalTitle = @model.get 'title'
        newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', originalTitle
        if '-' == newTitle
          @model.parent?.children()?.remove @model
        else
          @model.set 'title', newTitle if newTitle


    initialize: ->
      # grab the child collection from the parent model
      # so that we can render the collection as children
      # of this parent node
      @collection = @model.children()

      @listenTo @model, 'all', (name, model, collection, options) =>
        return if model != @model
        # Reduce the number of re-renderings that occur by filtering on the
        # type of event.
        # **FIXME:** Just listen to the relevant events
        switch name
          when 'change' then return
          when 'change:title' then @render()
          when 'change:treeNode' then return
          else return

      if @collection
        # If the children drop to/from 0 rerender so the (+)/(-) expandos are visible
        @listenTo @collection, 'add',    =>
          if @collection.length == 1
            @expand(true)
        @listenTo @collection, 'remove', =>
          if @collection.length == 0
            @render()
        @listenTo @collection, 'reset',  => @render()

        @listenTo @collection, 'all', (name, model, collection, options=collection) =>
          # Reduce the number of re-renderings that occur by filtering on the
          # type of event.
          # **FIXME:** Just listen to the relevant events
          switch name
            when 'change' then return
            when 'change:title' then return
            when 'change:treeNode' then return
            else @render() if @model == options?.parent

      # If the content title changes and we have not overridden the title
      # rerender the node
      if @model != @model.dereference()
        contentModel = @model.dereference()
        @listenTo contentModel, 'change:title', (newTitle, model, options) =>
          @render() if !@model.get 'title'


    templateHelpers: ->
      return {
        children: @collection?.length
        # Some rendered nodes are pointers to pieces of content. include the content.
        content: @model.dereference().toJSON() if @model != @model.dereference()
        editAction: !!@model.editAction
        parent: !!@model.parent
      }


    onRender: ->

      @$el.attr 'data-media-type', @model.mediaType
      $body = @$el.children '.editor-node-body'

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>
        _EnableContentDragging(@model, $body.children '*[data-media-type]')

        validSelectors = _.map @model.accepts(), (mediaType) -> "*[data-media-type=\"#{mediaType}\"]"
        validSelectors = validSelectors.join ','

        expandTimeout = null
        expandNode = => @toggleExpanded(true) if @collection?.length > 0

        $body.children('.editor-drop-zone').add(@$el.children('.editor-drop-zone')).droppable
          greedy: true
          addClasses: false
          accept: validSelectors
          activeClass: 'editor-drop-zone-active'
          hoverClass: 'editor-drop-zone-hover'
          # If hovering over a node that has children but is not expanded
          # Expand after a period of time.
          # over: => expandTimeout = setTimeout(expandNode, DELAY_BEFORE_SAVING)
          # out: => clearTimeout expandTimeout

          drop: (evt, ui) =>
            # Possible drop cases:
            #
            # - On the node
            # - Before the node
            # - After the node

            $drag = ui.draggable
            $drop = jQuery(evt.target)

            # Perform all of these DOM cleanup events once jQueryUI is finished with its events
            delay = =>

              drag = $drag.data('editor-model')

              # Ignore if you drop on yourself or your children
              testNode = @model
              while testNode
                return if (drag.cid == testNode.cid) or (testNode.id and drag.id == testNode.id)
                testNode = testNode.parent

              if $drop.hasClass 'editor-drop-zone-before'
                col = @model.parent.children()
                index = col.indexOf(@model)
                @model.parent.addChild drag, index
              else if $drop.hasClass 'editor-drop-zone-after'
                col = @model.parent.children()
                index = col.indexOf(@model)
                @model.parent.addChild drag, index + 1
              else if $drop.hasClass 'editor-drop-zone-in'
                @model.addChild drag
              else
                throw 'BUG. UNKNOWN DROP CLASS'

            setTimeout delay, 100

    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)


  # Use this to generate HTML with extra divs for Drag-and-Drop zones.
  #
  # To update the Book model when a `drop` occurs we convert the new DOM into
  # a JSON tree and set it on the model.
  #
  # **FIXME:** Instead of a JSON tree this Model should be implemented using a Tree-Like Collection that has a `.toJSON()` and methods like `.insertBefore()`
  exports.BookEditView = Marionette.CompositeView.extend
    template: BOOK_EDIT
    itemView: BookEditNodeView
    itemViewContainer: '> nav > ol'

    events:
      'click .editor-content-title': 'changeTitle'
      'click .editor-go-workspace': 'goWorkspace'

    changeTitle: ->
      title = prompt 'Enter a new Title', @model.get('title')
      @model.set 'title', title if title
    goWorkspace: -> Controller.workspace()

    initialize: ->
      @collection = @model.children()

      @listenTo @model, 'change:title', => @render()

    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)

  return exports
