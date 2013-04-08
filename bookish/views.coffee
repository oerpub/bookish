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
], (exports, _, Backbone, Marionette, jQuery, Aloha, Controller, Models, MEDIA_TYPES, Languages, CONTENT_EDIT, SEARCH_BOX, SEARCH_RESULT, SEARCH_RESULT_ITEM, DND_HANDLE, DIALOG_WRAPPER, EDIT_METADATA, EDIT_ROLES, LANGUAGE_VARIANTS, ALOHA_TOOLBAR, SIGN_IN_OUT, BOOK_EDIT, BOOK_EDIT_NODE, __) ->


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
  _EnableContentDragging = ($els) ->
    $els.each (i, el) ->
      $el = jQuery(el)
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
          title = $el.data 'content-title'
          shortTitle = title
          shortTitle = title.substring(0, 20) + '...' if title.length > 20
          # Generate the handle div using a template
          $handle = jQuery DND_HANDLE
            id: $el.data 'content-id'
            mediaType: $el.data 'media-type'
            title: title
            shortTitle: shortTitle
          return $handle


  # **FIXME:** Move this delay into a common module so the mock AJAX code can use them too
  DELAY_BEFORE_SAVING = 3000

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
      @$el.on 'click', => Controller.editModel(@model)
      # Add DnD options to content
      $content = @$el.children('*[data-media-type]')

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>

        _EnableContentDragging($content)

        # Figure out which mediaTypes can be dropped onto each element
        $content.each (i, el) =>
          $el = jQuery(el)
          validSelectors = []
          mediaType = MEDIA_TYPES.get @model.mediaType
          for acceptsType in _.keys mediaType?.accepts or {}
            validSelectors.push "*[data-media-type=\"#{acceptsType}\"]"

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
                model = Models.ALL_CONTENT.get $drag.data 'content-id'
                drop = Models.ALL_CONTENT.get $drop.data 'content-id'
                mediaType.accepts[model.mediaType](drop, model)


    # Add the hasChanged bit to the resulting JSON so the template can render an asterisk
    # if this piece of content has unsaved changes
    templateHelpers: ->
      # Figure out if the model was just fetched (all the changed attributes used to be 'undefined')
      # or if the attributes did actually change

      # Delete any properties that were null before
      changes = @model.changedAttributes() or {}
      (delete changes[attribute] if not @model.previous(attribute)) for attribute of changes

      # If there was anything that was actually changed (not null before) then mark the save button.
      return {hasChanged: _.keys(changes).length}


  # This can also be thought of as the Workspace view
  exports.SearchResultsView = Marionette.CompositeView.extend
    template: SEARCH_RESULT
    itemViewContainer: 'tbody'
    itemView: exports.SearchResultsItemView

    initialize: ->
      @listenTo @collection, 'reset',   => @render()
      @listenTo @collection, 'add',     => @render()
      @listenTo @collection, 'remove',  => @render()

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
      # Bind a function to the window if the user tries to navigate away from this page
      beforeUnload = =>
        return 'You have unsaved changes. Are you sure you want to leave this page?' if @hasChanged
      jQuery(window).on 'beforeunload', beforeUnload

      @listenTo @model, 'change', => @render()
      @listenTo @model, 'change:userid', => @render()

      # Listen to all changes made on Content so we can update the save button
      @listenTo Models.ALL_CONTENT, 'change', (model, b,c) =>
        # Figure out if the model was just fetched (all the changed attributes used to be 'undefined')
        # or if the attributes did actually change

        $save = @$el.find '#save-content'
        checkIfContentActuallyChanged = =>
          if model.hasChanged()
            @hasChanged = true
            $save.removeClass('disabled')
            $save.addClass('btn-primary')

        setTimeout (=> checkIfContentActuallyChanged()), 100

      @listenTo Models.ALL_CONTENT, 'change:treeNode add:treeNode remove:treeNode', (model, b,c) =>
        @hasChanged = true
        $save = @$el.find '#save-content'
        $save.removeClass('disabled')
        $save.addClass('btn-primary')


      # If the repo changes and all of the content is reset, update the button
      disableSave = =>
        @hasChanged = false
        $save = @$el.find '#save-content'
        $save.addClass('disabled')
        $save.removeClass('btn-primary')

      @listenTo Models.ALL_CONTENT, 'sync', disableSave
      @listenTo Models.ALL_CONTENT, 'reset', disableSave

      # Listen to model changes
      @listenTo @model, 'change', => @render()

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

      allContent = Models.ALL_CONTENT.filter (model) -> model.hasChanged()
      total = allContent.length
      errorCount = 0
      finished = false

      recSave = ->
        $successBar.width(((total - allContent.length - errorCount) * 100 / total) + '%')
        $errorBar.width((  errorCount                               * 100 / total) + '%')

        if allContent.length == 0
          if errorCount == 0
            finished = true
            Models.ALL_CONTENT.trigger 'sync'
            # Clear the dirty flag
            Models.ALL_CONTENT.each (model) -> delete model.changed
            $save.modal('hide')
          else
            $alertError.removeClass 'hide'

        else
          model = allContent.shift()
          $label.text(model.get('title'))

          # Clear the changed bit since it is saved.
          #     delete model.changed
          #     saving = true; recSave()
          saving = model.save null,
              success: recSave
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
      , 5000)




  # Book Editing
  # -------
  # The book editor has a tree of node views (nested `Marionette.ContainerView`)
  # with Drag and Drop handling restricted by `mediaType`.

  BookEditNodeView = Marionette.CompositeView.extend
    template: BOOK_EDIT_NODE
    tagName: 'li'
    events:
      'click > .edit-content': 'editContent'
      'click > .edit-settings': 'editSettings'
      'click > .editor-expand-collapse': 'toggleExpanded'

    editContent: -> Controller.editModelId @model.contentId()

    editSettings: ->
      contentModel = Models.ALL_CONTENT.get @model.contentId()
      originalTitle = contentModel?.get('title') or @model.get 'title'
      newTitle = prompt 'Edit Title. Enter a single "-" to delete this node in the ToC', originalTitle
      if '-' == newTitle
        @model.parent.children.remove @model
      else if newTitle == contentModel?.get('title')
        @model.unset 'title'
      else if newTitle
        @model.set 'title', newTitle


    toggleExpanded: ->
      # Set the expanded state silently so we don't regenerate the `navTreeStr`
      # (since the model changed)
      @model.set 'expanded', !@model.get('expanded'), {silent:true}
      @render()


    initialize: ->
      # grab the child collection from the parent model
      # so that we can render the collection as children
      # of this parent node
      @collection = @model.children

      @listenTo @model,      'all', => @render()
      @listenTo @collection, 'all', => @render()

      # If the content title changes and we have not overridden the title
      # rerender the node
      if @model.contentId()
        contentModel = Models.ALL_CONTENT.get @model.contentId()
        @listenTo contentModel, 'change:title', (newTitle, model, options) =>
          @render() if !@model.get 'title'


    templateHelpers: ->
      if @model.contentId()
        content = Models.ALL_CONTENT.get @model.contentId()
        # Provide the original module title to view templates
        # if the title has not been overridden

        # **FIXME:** Just make the whole Content model available via `.content`
        # instead of picking out the `title` and `mediaType`
        return {
          _contentTitle: content.get 'title'
          _contentMediaType: content.mediaType
        }


    # From `Marionette.CompositeView`.
    # Added check to only render when model is `expanded`
    _renderChildren: ->
      if @isRendered and @model.get('expanded')
        Marionette.CollectionView.prototype._renderChildren.call(@)
        this.triggerMethod('composite:collection:rendered')


    onRender: ->

      @$el.children('.organization-node,*[data-media-type]').data 'content-tree-node', @model

      # Since we use jqueryui's draggable which is loaded when Aloha loads
      # delay until Aloha is finished loading
      Aloha.ready =>
        _EnableContentDragging(@$el.children '.organization-node,*[data-media-type]')

        @$el.addClass 'editor-drop-zone editor-drop-zone-in'
        @$el.add(@$el.children('.editor-drop-zone')).droppable
          greedy: true
          addClasses: false
          accept: '.organization-node,*[data-media-type]'
          activeClass: 'editor-drop-zone-active'
          hoverClass: 'editor-drop-zone-hover'
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

              # If $drag is not a `li.organization-node` then it has a `*[data-media-type]`
              # and should be converted to a link inside an `li`

              drag = $drag.data('content-tree-node') or {
                id: $drag.data 'content-id'
                # The title and mediaType should inherit from the actual piece of content
                #    title: $drag.data 'content-title'
                #    mediaType: $drag.data 'media-type'
              }

              # Ignore if you drop on yourself or your children
              testNode = @model
              while testNode
                return if (drag.cid == testNode.cid) or (testNode.id and drag.id == testNode.id)
                testNode = testNode.parent

              # Remove the item if it is a `BookTocNode`
              drag.parent.children.remove(drag) if drag.parent

              if $drop.hasClass 'editor-drop-zone-before'
                col = @model.parent.children
                index = col.indexOf(@model)
                col.add drag, {at: index}
              else if $drop.hasClass 'editor-drop-zone-after'
                col = @model.parent.children
                index = col.indexOf(@model)
                col.add drag, {at: index + 1}
              else if $drop.hasClass 'editor-drop-zone-in'
                @model.children.add drag
              else
                throw 'BUG. UNKNOWN DROP CLASS'

            setTimeout delay, 100

    appendHtml: (cv, iv) -> cv.$('ol:first').append(iv.el)


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
    # Default media type for new Content
    contentMediaType: 'application/vnd.org.cnx.module'

    events:
      'click #nav-close': 'closeView'
      'click #add-section': 'prependSection'
      'click #add-content': 'prependContent'

    initialize: ->
      @collection = @model.navTreeRoot.children

    # **FIXME:** Make the mediaType for new content a property of the view
    # (so the EPUB book editor can override it) or use `media-types` to look it up.
    prependSection: -> @model.prependNewContent {title: 'Untitled Section'}
    prependContent: -> @model.prependNewContent {title: 'Untitled Content'}, @contentMediaType

    closeView: -> Controller.hideSidebar()

    appendHtml: (cv, iv, index)->
      $container = @getItemViewContainer(cv)
      $prevChild = $container.children().eq(index)
      if $prevChild[0]
        iv.$el.insertBefore($prevChild)
      else
        $container.append(iv.el)

  return exports
