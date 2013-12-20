define [
  'cs!views/layouts/workspace/sidebar'
  'hbs!templates/layouts/workspace/table-of-contents'
], (Sidebar, tocTemplate) ->

  return class TocSidebar extends Sidebar
    template: tocTemplate
