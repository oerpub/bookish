define ['cs!./new-id'], (newId) ->
  return (fields) ->
    throw 'BUG! title required' if not fields.title
    throw 'BUG! HTML body required' if fields.body and fields.body[0] != '<'

    fields.mediaType = 'application/vnd.org.cnx.module'
    fields.id ?= newId(fields)
    fields.body ?= '<p>A Simple Paragraph</p>'
    fields.dateLastModifiedUTC ?= (new Date()).toJSON()
    return fields
