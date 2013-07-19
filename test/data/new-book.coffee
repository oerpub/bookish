define ['cs!./new-id'], (newId) ->
  return (fields) ->
    throw 'BUG! title required' if not fields.title
    throw 'BUG! HTML body required' if fields.body and not $('<div></div>').append(fields.body).children().length == 0

    fields.mediaType = 'application/vnd.org.cnx.collection'
    fields.id ?= newId(fields)
    fields.dateLastModifiedUTC ?= (new Date()).toJSON()
    fields.body ?= '<nav><ol></ol></nav>'
    return fields
