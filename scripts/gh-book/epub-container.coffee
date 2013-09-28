# All Content
# =======
#
# To prevent multiple copies of a model from floating around a single
# copy of all referenced content (loaded or not) is kept in this Collection
#
# This should be read-only by others
# New content models should be created by calling `ALL_CONTENT.add {}`

define [
  'cs!collections/content'
  'cs!models/content/inherits/saveable'
  'cs!mixins/loadable'
  'cs!mixins/tree'
  'cs!gh-book/opf-file'
], (allContent, Saveable, loadableMixin, treeMixin, OpfFile) ->


  class EpubContainer extends Saveable
    mediaType: 'application/epub+zip'
    accept: [OpfFile::mediaType]

    defaults:
      urlRoot: ''
    id: 'META-INF/container.xml'

    initialize: () ->
      @children = new Backbone.Collection()

      @children.on 'reset', (collection, options) =>
        return if options.loading

        allContent.reset(@children.models)

    # Extend the `load()` to wait until all content is loaded
    _loadComplex: (fetchPromise) ->
      return fetchPromise.then () =>
        contentPromises = @children.map (model) => model.load()
        # Return a new promise that finishes once all the contentPromises have loaded
        return $.when.apply($, contentPromises)

    parse: (json) ->
      # Github.read returns a `{sha: "1234", content: "<rootfiles>...</rootfiles>"}
      sha = json.sha
      xmlStr = json.content

      $xml = jQuery(xmlStr)
      ret = []
      $xml.find('rootfiles > rootfile').each (i, el) =>
        $el = jQuery(el)
        href = $el.attr 'full-path'
        mediaType = $el.attr 'media-type'
        model = allContent.get(href)
        if not model
          model = allContent.model {id: href, mediaType: mediaType}
          allContent.add(model, {loading:true})
        ret.push model

      return @children.reset(ret, {loading:true})

    serialize: () -> console.warn('BUG: Do not know how to serialize EPUBContainer yet')

    # Called by `loadableMixin.reload` when the repo settings change
    reset: () -> @children.reset()

    addChild: (book) -> @children.add(book)

  EpubContainer = EpubContainer.extend loadableMixin
  # All content in the Workspace
  return EpubContainer
