define ['cs!./new-module'], (newModule) ->
  return {
    content: [
      newModule {title: 'Simple Module', body: '<p>The body of a Simple Module</p>'}
    ]
  }
