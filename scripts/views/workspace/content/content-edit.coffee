define [
  'cs!views/workspace/content/aloha-edit'
  'hbs!templates/workspace/content/content-edit'
], (AlohaEditView, contentEditTemplate) ->

  # Edit Content Body
  # -------
  return class ContentEditView extends AlohaEditView
    modelKey: 'body'
    
    # **NOTE:** This template is not wrapped in an element
    template: contentEditTemplate

    initialize: () ->
      # CAVEAT: initialize is called every time a module is opened, so
      # we're modifying the aloha config on every module open. That is not
      # problematic, but it can be done more efficiently.
      Aloha.settings.plugins.metadata = Aloha.settings.plugins.metadata || {}
      Aloha.settings.plugins.metadata.supplement = ''

      Aloha.settings.plugins.metadata.setMetadata = (metadata) =>
        @model.set('title', metadata.title, {triggeredByMetadata: true})
        head = '<title>'+metadata.title+'</title>'
        head += '<meta data-type="language" itemprop="inLanguage" content="'+metadata.language+ '" />'
        @model.set('head', head)

      Aloha.settings.plugins.metadata.filterMetadata = (metadata) =>
        delete metadata.language if metadata.language
        metadata

      @listenTo @model, "change:title", (model, value, options) =>
        if not options.triggeredByMetadata
          Aloha.require('metadata/metadata-plugin').extendMetadata
            title: value
      
      @listenTo @model, "change:head", (model, value, options) =>
        # sometimes there is no head. which is dumb.
        if @model.get('head')
          Aloha.settings.plugins.metadata.supplement = @model.get('head')
        else
          Aloha.settings.plugins.metadata.supplement = "<title>" + @model.get("title") + "</title>"

      # Tell the metadata plugin how to get the initial title
      Aloha.settings.plugins.metadata.getInitialMetadata = () =>
        return { title: @model.get('title') }

      super()
