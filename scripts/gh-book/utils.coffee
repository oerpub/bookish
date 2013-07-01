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


    # Given 2 paths that have the same root
    # generate a path that is relative from `context` to `relPath`.
    # For example: `A/B/cntx` and `A/C/D/file.txt` should yield `../C/D/file.txt`
    relativePath: (contextPath, targetPath) ->
      return targetPath if contextPath.search('/') < 0
      contextParts = contextPath.split('/')
      targetParts = targetPath.split('/')

      # Pop the end of both so we only deal with directories
      contextParts.pop()
      targetName = targetParts.pop()

      sameUntil = contextParts.length
      for part, i in contextParts
        if part != targetParts[i]
          sameUntil = i
          break

      if sameUntil == contextParts.length
        parts = []
      else
        parts = ('..' for i in [sameUntil..contextParts.length-1])

      # We have all the '..'; now add in the rest of parts
      parts = parts.concat targetParts.slice(sameUntil)
      parts.push targetName
      parts.join '/'


    elementAttributes: ($el) ->
      attrs = {}
      $.each $el[0].attributes, (index, attr) =>
        attrs[attr.name] = attr.value
      attrs
  }
