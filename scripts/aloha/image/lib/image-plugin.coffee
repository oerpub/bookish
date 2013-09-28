define ['aloha', 'aloha/plugin'], (Aloha, Plugin) ->
  Plugin.create 'ghbook-image',
    init: () ->
      Aloha.require ['assorted/image'], (Image) ->
        # Override the normal uploadImage functionality
        Image.uploadImage = (file, el, callback) ->
          # Do any gh-book specific handing here. Presently nothing to do
          # as the plugin itself already stores the image base64 encoded
          # in the document.
