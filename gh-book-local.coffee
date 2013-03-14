require.config
  paths:

    # Change the Stub Auth piece
    'aloha': 'lib/Aloha-Editor/src/lib/aloha'


# This file acts as a mock store so a connection to github is not necessary
# Useful for local development
require ['jquery', 'backbone', 'gh-book'], (jQuery, Backbone) ->

  # The number of milliseconds before calling a callback
  # If set to 0 then the callback will be called immediately

  # Setting a delay simulates network latency while 0 delay simulates loading the content on page load
  CALLBACK_DELAY = 0

  DEBUG = true

  OPF_ID = '12345'
  OPF_TITLE = 'Github EPUB Editor'
  OPF_LANGUAGE = 'en'

  OPF_PATH = 'book.opf'
  NAV_PATH = 'navigation.html'
  CH1_PATH = 'background.html'
  CH2_PATH = 'introduction.html'

  CH1_ID = 'id-1-background'
  CH2_ID = 'id-2-intro'

  window.FILES = {}
  FILES['META-INF/container.xml'] = """
        <?xml version='1.0' encoding='UTF-8'?>
        <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
         <rootfiles>
            <rootfile full-path="#{OPF_PATH}" media-type="application/oebps-package+xml"/>
         </rootfiles>
        </container>
    """
  FILES[OPF_PATH] = """
        <?xml version="1.0"?>
        <package version="3.0"
                 xml:lang="en"
                 xmlns="http://www.idpf.org/2007/opf"
                 unique-identifier="pub-id">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                <dc:identifier
                      id="pub-id">#{OPF_ID}</dc:identifier>
                <meta refines="#pub-id"
                      property="identifier-type"
                      scheme="xsd:string">uuid</meta>

                <dc:language>#{OPF_LANGUAGE}</dc:language>
                <dc:title>#{OPF_TITLE}</dc:title>

            </metadata>

            <manifest>
                <item id="id-navigation"
                      properties="nav"
                      href="#{NAV_PATH}"
                      media-type="application/xhtml+xml"/>
                <item id="#{CH2_ID}"
                      href="#{CH2_PATH}"
                      media-type="application/xhtml+xml"/>
                <item id="#{CH1_ID}"
                      href="#{CH1_PATH}"
                      media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
                <itemref idref="#{CH1_ID}"/>
                <itemref idref="#{CH2_ID}"/>
            </spine>
        </package>
        """
  FILES[NAV_PATH] = """
      <p>Example Navigation</p>
      <nav>
        <ol>
          <li><a href="#{CH1_PATH}">Background Information</a></li>
          <li>
            <span>Chapter 1</span>
            <ol>
              <li><a href="#{CH2_PATH}">Introduction to gh-book</a></li>
            </ol>
          </li>
        </ol>
      </nav>
      """
  FILES[CH1_PATH] = '<h1>Background</h1>'
  FILES[CH2_PATH] = '<h1>Introduction</h1>'
  FILES['background.json'] = JSON.stringify {title: 'Background Module Title'}

  readFile = (path) -> (promise) ->
    if path of FILES
      promise.resolve FILES[path]
    else
      promise.fail {message: 'IN_MEM_COULD_NOT_FIND_FILE'}

  writeFile = (path, data) -> (promise) ->
    FILES[path] = data
    promise.resolve {message: 'IN_MEM_SAVED'}

  delay = (operation) ->
    promise = new jQuery.Deferred()
    fn = -> operation(promise)
    if 0 == CALLBACK_DELAY
      fn()
    else
      setTimeout fn, CALLBACK_DELAY
    return promise


  Backbone.sync = (method, model, options) ->
    path = model.id or model.url?() or model.url

    console.log method, path if DEBUG?

    switch method
      when 'read' then ret = delay readFile(path)
      when 'update' then ret = delay writeFile(path, model.serialize())
      when 'create'
        # Create an id if this model has not been saved yet
        id = _uuid()
        model.set 'id', id
        ret = delay writeFile(path, model.serialize())
      else throw "Model sync method not supported: #{method}"

    ret.done (value) => options?.success?(model, value, options)
    ret.fail (error) => options?.error?(model, error, options)
    return ret
