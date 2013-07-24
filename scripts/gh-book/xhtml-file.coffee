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

    defaults:
      title: null

    initialize: () ->
      super()
      # Clear that the title on the model has changed
      # so it does not get saved unnecessarily.
      # The title of the XhtmlFile is not stored inside the file;
      # it is stored in the navigation file
      @on 'change:title', (model, value, options) =>
        head = @get 'head'
        $head = jQuery("<div class='unwrap-me'>#{head}</div>")

        $head.children('title').text(value)
        @set 'head', $head[0].innerHTML, options


    parse: (json) ->
      # Save the commit sha so we can compare when a remote update occurs
      @commitSha = json.sha
      html = json.content

      # If the parse is a result of a write then update the sha.
      # The parse is a result of a GitHub.write if there is no `.content`
      return {} if not json.content

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

      # When an `<img src="...">` is parsed by jQuery the src attribute is fetched
      # even if the image hasn't been added to the DOM yet.
      # Instead of letting that silently fail,
      # replace the `img` tag with another element until the bytes are retrieved
      # via the github API.
      html = html.replace(/<img/g, '<prefix-img')
      html = html.replace(/<\/img>/g, '</prefix-img>')

      $html = jQuery(html)

      $head = $html.find('prefix-head')
      $body = $html.find('prefix-body')

      # Change the `src` attribute to be a `data-src` attribute if the URL is relative
      $html.find('prefix-img').each (i, img) ->
        $imgHolder = jQuery(img)
        src = $imgHolder.attr 'src'
        return if /^https?:/.test src
        return if /^data:/.test src

        $imgHolder.removeAttr 'src'

        # Replace the `<prefix-img>` with a real `<img>` and set the `src` attribute
        $img = jQuery('<img></img>')
        $img.attr 'data-src', src
        # Transfer all the attributes to `$img`
        $img.attr(Utils.elementAttributes $imgHolder)

        $imgHolder.replaceWith $img


      $images = $html.find('img[data-src]')
      counter = $images.length

      $images.each (i, img) =>
        $img = jQuery(img)
        src = $img.attr 'data-src'
        path = Utils.resolvePath @id, src
        imageModel = allContent.get(path)
        if ! imageModel
          console.error "ERROR: Manifest missing image file #{path}"
          counter--
          # Set `parse:true` so the dirty flag for saving is not set
          @set 'body', $body[0].innerHTML, {parse:true, loading:true} if counter == 0
          return

        # Load the image file somehow (see below for my github.js changes)
        doneLoading = imageModel.load()
        .done (bytes, statusMessage, xhr) =>
          # Grab the mediaType from the response header (or look in the EPUB3 OPF file)
          mediaType = imageModel.mediaType # xhr.getResponseHeader('Content-Type').split(';')[0]

          encoded = imageModel.get 'base64Encoded'
          $img.attr('src', "data:#{mediaType};base64,#{encoded}")

          counter--
          # Set `parse:true` so the dirty flag for saving is not set
          @set 'body', $body[0].innerHTML, {parse:true, loading:true} if counter == 0

        .fail ->
          counter--
          $img.attr('src', 'path/to/failure.png')

      attributes = {head:$head[0]?.innerHTML, body:$body[0]?.innerHTML}

      # Set the title that is in the `<head>`
      title = $head.children('title').text()
      attributes.title = title if title

      return attributes


    serialize: ->
      head = @get 'head'
      body = @get 'body'
      $head = jQuery("<div class='unwrap-me'>#{head}</div>")
      $body = jQuery("<div class='unwrap-me'>#{body}</div>")

      # Replace all the `img[data-src]` attributes with `img[src]`
      $body.find('img[data-src]').each (i, img) ->
        $img = jQuery(img)
        src = $img.attr('data-src')
        $img.removeAttr('data-src')
        $img.attr 'src', src

      return """
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
          <head>
            #{$head[0].innerHTML}
          </head>
          <body>
            #{$body[0].innerHTML}
          </body>
        </html>
        """
