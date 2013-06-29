define ['jquery'], ($) ->

  return {
    # Links in a navigation document are relative to where the nav document resides.
    # If it does not live in the same directory then they need to be resolved to
    # an absolute path so content Models can be looked up
    resolvePath: (context, relPath) ->
      return relPath if context.search('/') < 0
      path = context.replace(/\/[^\/]*$/, '') + '/' + relPath.split('#')[0]
      # path may still contain '..' so clean those up
      parts = path.split('/')

      i = 0
      while i < parts.length
        switch parts[i]
          when '.' then parts.splice(i, 1)
          when '..' then parts.splice(i-1, 2); i -= 1
          else i++

      parts.join '/'


    elementAttributes: ($el) ->
      attrs = {}
      $.each $el[0].attributes, (index, attr) =>
        attrs[attr.name] = attr.value
      attrs
  }
