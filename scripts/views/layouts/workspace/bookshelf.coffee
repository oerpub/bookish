define [
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace/bookshelf'
  'cs!configs/languages'
  'bootstrapModal'
  'bootstrapTab'
  'bootstrapTags'
], (Sidebar, bookshelfTemplate, languages) ->

  return class BookshelfSidebar extends Sidebar
    template: bookshelfTemplate

    initialize: (options) ->
      super(options)

    templateHelpers: () ->

      return {
        languages: languages
      }

    editBook: (book) ->
      console.log book

      modal = $('#edit-book-modal').modal {show:true}

      modal.find('[data-role="tagsinput"]').tagsinput({
        confirmKeys: [13, 188, 9]
      })
      modal.find('[data-edit-toggle]').click ->
        $(this).hide().siblings('input').show().focus()
      .siblings('input').blur ->
        $(this).hide().siblings('[data-edit-toggle]').show().find('[data-title]').text($(this).val())

      modal.find('a[data-toggle="tab"]').on('shown', (e) ->
        if $(e.target).parents('li').next().length
          modal.find('[data-tab-next]').text('Next')
        else
          modal.find('[data-tab-next]').text('Save')
      )
    
      # populate book data in the form
      modal.find('input[name="title"]').val(book.get('title')).blur()

      modal.find('[data-tab-next]').click ->
        next = modal.find('.nav li.active').next()

        if next.length
          next.find('a').click()
        else
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
            subject: modal.find('[name="subject"]').val().split(',')
            keywords: modal.find('[name="keywords"]').val().split(',')
            rightsHolders: modal.find('[name="rights-holders"]').val().split(',')
            authors: modal.find('[name="authors"]').val().split(',')
            publishers: modal.find('[name="publishers"]').val().split(',')
            editors: modal.find('[name="editors"]').val().split(',')
            translators: modal.find('[name="translators"]').val().split(',')
            illustrators: modal.find('[name="illustrators"]').val().split(',')

          modal.modal('hide')
