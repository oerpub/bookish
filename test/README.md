Working with Mock Data
=======================

You can open the HTML file in a Browser and test the workspace.

You can **also** extract all the mock data by running `npm run print-mock-data`
or by directly running `node ./test/print-mock-data`.

This will return a JSON object with 2 keys:

- `content`: contains an array of Modules, Books, and Folders
- `resources`: contains an Object whose keys are a hash and
     values are a string representing the resource (SVG, binary data, etc)


If you want to reduce the set just comment some lines in `./all-mock-data.coffee`.


API Verbs
==========

The Verbs and URLs used for testing the client are in `./demo-mock.coffee`.
This is also the file that contains the in-memory (mock) repository.
