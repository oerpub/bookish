define ['cs!./new-module'], (newModule) ->
  moduleA = newModule {title: 'ModuleA which links to ModuleB'}
  moduleB = newModule {title: 'ModuleB which links to ModuleA'}

  moduleA.body = "<p>Link to <a href='#{moduleB.id}'>ModuleB<a></p>"
  moduleB.body = "<p>Link to <a href='#{moduleA.id}'>ModuleA<a></p>"
  return {
    content: [
      moduleA
      moduleB
    ]
  }
