# Returns a new uuid. Can be swapped out for an incremental counter for deterministic testing
define [], () ->
  # Generate UUIDv4 id's (from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript)
  uuid = b = (a) ->
    (if a then (a ^ Math.random() * 16 >> a / 4).toString(16) else ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, b))

  prettyUuid = (seed) ->
    return uuid() if not seed

    prefix = seed.toLowerCase()
      .replace(' ', '-')
      .replace(/[^a-z0-9\-]/, '') # prevent any weird characters from slipping through
    
    return "#{prefix}-#{uuid()}" # add the random uuid on the back for uniqueness 

  return prettyUuid
