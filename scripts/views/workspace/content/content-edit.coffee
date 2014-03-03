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
      Aloha.settings.plugins.metadata = Aloha.settings.plugins.metadata || {}
      Aloha.settings.plugins.metadata.supplement = ''

      Aloha.settings.plugins.metadata.setMetadata = (metadata) =>
        @model.set('title', metadata.title)
        head = '<title>'+metadata.title+'</title>'
        head += '<meta data-type="language" itemprop="inLanguage" content="'+metadata.language+ '" />'
        @model.set('head', head)

      Aloha.settings.plugins.metadata.filterMetadata = (metadata) =>
        delete metadata.language if metadata.language
        metadata

      @listenTo @model, "change:head", (model, value, options) =>
        # sometimes there is no head. which is dumb.
        if @model.get('head')
          Aloha.settings.plugins.metadata.supplement = @model.get('head')
        else
          Aloha.settings.plugins.metadata.supplement = "<title>" + @model.get("title") + "</title>"

      super()
