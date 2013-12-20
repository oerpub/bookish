define [
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace/bookshelf'
], (Sidebar, bookshelfTemplate) ->

  return class BookshelfSidebar extends Sidebar
    template: bookshelfTemplate
