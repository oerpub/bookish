define ['cs!./new-module'], (newModule) ->
  return {
    content: [
      newModule
        title: 'Module With Metadata'
        language: 'zh-tw'
        dateCreatedUTC: '2012-02-29T12:03:13.159627'
        dateLastModifiedUTC: '2012-02-29T12:03:13.159627'
        summary: """
          <p>A Summary With a list and Math for giggles</p>
          <ol>
            <li>Item 1</li>
            <li>Item 2</li>
          </ol>
          <math xmlns="http://www.w3.org/1998/Math/MathML">
            <annotation encoding="ASCIIMath">x/2</annotation>
            <mfrac>
              <mi>x</mi>
              <mn>2</mn>
            </mfrac>
          </math>
          """

        maintainers: ['Bruce Wayne', 'Peter Parker']
        copyrightHolders: ['Cory Dr O', 'Mr Applebaum']
        authors: ['Albert', 'Betsy']
        editors: ['Clark Kent', 'Peter Parker']
        translators: ['John Ronald Reuel Tolkien']
        subjects: ['Mathematics', 'Algebra', 'Abstract Algebra']
        keywords: ['keyword1', 'keyword with spaces', 'keyword with, comma']
        googleTrackingID: 'UA-1234567-1'

        subType: null # Not used

        body: '<p>This module has a simple body but a Bunch of metadata</p>'
    ]
  }
