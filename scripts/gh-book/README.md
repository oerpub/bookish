# Configuring the Editor

## Loading from GitHub

You can customize the repo that is loaded by adding the following to the URL: `#repo/[USER_NAME]/[REPO_NAME]`

You may also need to add a token so GitHub does not rate limit.
In `./app.coffee` change `new Github()` so something like `new Github({auth: 'oauth', token: 'YOUR_TOKEN_HERE'})` with a token obtained from https://github.com/settings/applications (Click "Create new token")

## Local "Mock" Book

With this method you can load a book without using the GitHub API (you cannot save changes).
You will need to unzip an EPUB and host it somewhere on http://localhost

Some example Repositories you can use:

- https://github.com/philschatz/books (text from Physics and Biology books)
- https://github.com/philschatz/epub-anatomy (Anatomy text and many images)

Then, make the following changes:

1. Change `./app-local.coffee` to point to your unzipped book (ie `../books`)
2. update `../config.coffee` to load `cs!gh-book/app-local` instead of `cs!gh-book/app`

