define [], () ->
  counter = 0
  return (fields) ->
    # TODO: Generate an id based on the hash of the fields
    return "uuid-#{counter++}"
