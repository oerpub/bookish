define [
  'underscore'
  'backbone'
  'cs!models/content/module'
  'cs!collections/content'
  'cs!gh-book/utils'
], (_, Backbone, ModuleModel, allContent, Utils) ->

  # The `Content` model contains the following members:
  #
  # * `title` - an HTML title of the content
  # * `language` - the main language (eg `en-us`)
  # * `subjects` - an array of strings (eg `['Mathematics', 'Business']`)
  # * `keywords` - an array of keywords (eg `['constant', 'boltzmann constant']`)
  # * `authors` - an `Collection` of `User`s that are attributed as authors
  return class XhtmlModel extends ModuleModel
    mediaType: 'application/xhtml+xml'

    initialize: () ->
      @set 'title', @id, {silent:true}

    parse: (html) ->

      # The result of a Github PUT is an object instead of the new state of the model.
      # Basically ignore it.
      return html if 'string' != typeof html

      # Rename elements before jQuery parses and removes them
      # (because they are not valid children of a div)

      html = "<body>#{html}</body>" if not /<body/.test html
      html = "<html>#{html}</html>" if not /<html/.test html

      html = html.replace(/html>/g, "prefix-html>")
      html = html.replace(/<\/head>/g, "</prefix-head>")
      html = html.replace(/body>/g, "prefix-body>")

      html = html.replace(/<html/g, "<prefix-html")
      # Search for the exact element `<head>` since otherwise it could be
      # confused with `<header>`.
      html = html.replace(/<head>/g, "<prefix-head>")
      html = html.replace(/<body/g, "<prefix-body")

      $html = jQuery(html)

      $head = $html.find('prefix-head')
      $body = $html.find('prefix-body')

      # Change the `src` attribute to be a `data-src` attribute if the URL is relative
      $html.find('img').each (i, img) ->
        $img = jQuery(img)
        src = $img.attr 'src'
        return if /^https?:/.test src
        return if /^data:/.test src

        $img.removeAttr 'src'
        $img.attr 'data-src', src


      $images = $html.find('img[data-src]')
      counter = $images.length

      $images.each (i, img) =>
        $img = jQuery(img)
        src = $img.attr 'data-src'
        id = Utils.resolvePath @id, src
        imageModel = allContent.get(id)
        # Load the image file somehow (see below for my github.js changes)
        doneLoading = imageModel.fetch()
        .done (bytes, statusMessage, xhr) =>
          # Grab the mediaType from the response header (or look in the EPUB3 OPF file)
          mediaType = imageModel.mediaType # xhr.getResponseHeader('Content-Type').split(';')[0]

          encoded = imageModel.get 'base64Encoded'
          $img.attr('src', "data:#{mediaType};base64,#{encoded}")

          counter--
          @set 'body', $body[0].innerHTML if counter == 0

        .fail ->
          counter--
          $img.attr('src', 'path/to/failure.png')

      return {head: $head[0]?.innerHTML, body: $body[0]?.innerHTML}
