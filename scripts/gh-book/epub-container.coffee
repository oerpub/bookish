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
], (allContent, Saveable, loadableMixin, treeMixin) ->


  class EpubContainer extends Saveable
    mediaType: 'application/epub+zip'
    accept: ['application/oebps-package+xml'] # Hardcode the OpfFile::mediaType because otherwise there would be a cyclic dependency on allContent

    defaults:
      urlRoot: ''
    id: 'META-INF/container.xml'

    initialize: (options) ->
      options ?= {}
      options.root = @
      @_initializeTreeHandlers(options)

    # Extend the `load()` to wait until all content is loaded
    _loadComplex: (fetchPromise) ->
      return fetchPromise.then () =>
        contentPromises = @getChildren().map (model) => model.load()
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
          allContent.add(model)
        ret.push model

      @getChildren().reset(ret)

    # Called by `loadableMixin.reload` when the repo settings change
    reset: () ->
      @getChildren().reset()
      allContent.reset()


  EpubContainer = EpubContainer.extend loadableMixin
  EpubContainer = EpubContainer.extend treeMixin
  # All content in the Workspace
  return EpubContainer
