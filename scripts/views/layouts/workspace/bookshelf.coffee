define [
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace/bookshelf'
  'cs!configs/languages'
  'underscore'
  'bootstrapModal'
  'bootstrapTab'
  'bootstrapTags'
], (Sidebar, bookshelfTemplate, languages, _) ->

  return class BookshelfSidebar extends Sidebar
    template: bookshelfTemplate

    templateHelpers: () ->

      return {
        languages: languages
      }

    editBook: (book) ->
      modal = $('#edit-book-modal').modal {show:true}
      modal.find('.nav.nav-tabs li:first a').click()

      modal.find('[name="title"]').val(book.get('title'))
      modal.find('[name="language"]').val(book.get('language'))
      modal.find('[name="description"]').val(book.get('description'))
      modal.find('[name="language"]').val(book.get('language') || 'en')
      modal.find('[name="rights"]').val(book.get('rightsUrl'))

      modal.find('[data-role="tagsinput"]').each ->
        $(@).tagsinput({
          confirmKeys: [13, 188, 9]
        }) unless $(@).data('tagsinput')
        $(@).tagsinput('removeAll')

      _.each book.get('subject'), (subject) -> modal.find('[name="subject"]').tagsinput('add', subject)
      _.each book.get('keywords'), (keyword) -> modal.find('[name="keywords"]').tagsinput('add', keyword)
      _.each book.get('rightsHolders'), (rightsHolder) -> modal.find('[name="rights-holders"]').tagsinput('add', rightsHolder)
      _.each book.get('authors'), (author) -> modal.find('[name="authors"]').tagsinput('add', author)
      _.each book.get('publishers'), (publisher) -> modal.find('[name="publishers"]').tagsinput('add', publisher)
      _.each book.get('editors'), (editor) -> modal.find('[name="editors"]').tagsinput('add', editor)
      _.each book.get('translators'), (translator) -> modal.find('[name="translators"]').tagsinput('add', translator)
      _.each book.get('illustrators'), (illustrator) -> modal.find('[name="illustrators"]').tagsinput('add', illustrator)

      modal.find('[data-edit-toggle]').off('click').click ->
        $(this).hide().siblings('input').show().focus()
      .siblings('input').off('blur').blur ->
        $(this).hide().siblings('[data-edit-toggle]').show().find('[data-title]').text($(this).val())

      modal.find('a[data-toggle="tab"]').on('shown', (e) ->
        if $(e.target).parents('li').next().length
          modal.find('[data-tab-next]').show()
        else
          modal.find('[data-tab-next]').hide()
      )
    
      modal.find('[data-cancel]').off('click').click ->
        if confirm('Are you sure you want to close without saving? The title, authors, and other information about this book will retain their previous values.')
          modal.modal('hide')

      modal.find('[data-tab-next]').off('click').click ->
        next = modal.find('.nav li.active').next()
        next.find('a').click() if next.length

      # populate book data in the form
      modal.find('input[name="title"]').val(book.get('title')).blur()

      modal.find('[data-save]').off('click').click ->

        rightsUrl = modal.find('[name="rights"]').val()

        if rightsUrl.length
          rights = modal.find('[name="rights"] option[value="' + rightsUrl + '"]').text().trim()
        else
          rights = ''

        now = new Date()

        book.set
          title: modal.find('[name="title"]').val()
          description: modal.find('[name="description"]').val()
          language: modal.find('[name="language"]').val()
          rights: rights
          rightsUrl: rightsUrl
          dateModified: "#{now.getFullYear()}-#{now.getMonth()+1}-#{now.getDate()}"
          subject: modal.find('[name="subject"]').val().split(',').filter (i) -> i
          keywords: modal.find('[name="keywords"]').val().split(',').filter (i) -> i
          rightsHolders: modal.find('[name="rights-holders"]').val().split(',').filter (i) -> i
          authors: modal.find('[name="authors"]').val().split(',').filter (i) -> i
          publishers: modal.find('[name="publishers"]').val().split(',').filter (i) -> i
          editors: modal.find('[name="editors"]').val().split(',').filter (i) -> i
          translators: modal.find('[name="translators"]').val().split(',').filter (i) -> i
          illustrators: modal.find('[name="illustrators"]').val().split(',').filter (i) -> i

        modal.modal('hide')
