define ['cs!./new-id'], (newId) ->
  return (fields) ->
    throw 'BUG! title required' if not fields.title

    fields.mediaType = 'application/vnd.org.cnx.folder'
    fields.id ?= newId(fields)
    fields.contents ?= [] # Empty contents by default
    fields.dateLastModifiedUTC ?= (new Date()).toJSON()
    return fields
