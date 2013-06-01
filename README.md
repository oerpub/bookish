# Development and Building

Below are instructions for building the book editor yourself and a layout
of how the code is organized.

## Building Yourself

1. Download
2. Configure your server to point /workspace, /login, and /logout at index.html
3. (optional) Build a minified Javascript file by running `r.js` (see https://github.com/jrburke/r.js)

## Building Documentation

Documentation is built using `docco`.

    find . -name "*.coffee" | grep -v './lib/' | grep -v './node_modules' | xargs ./node_modules/docco/bin/docco

Check the `./docs` directory to read through the different modules.

## Directory Layout

* `scripts/collections/`   Backbone Collections
* `scripts/controllers/`   Marionette Controllers
* `scripts/libs/`          3rd Party Libraries
* `scripts/models/`        Backbone Models and Marionette Modules
* `scripts/routers/`       Marionette Routers
* `scripts/views/`         Backbone and Marionette Views
* `scripts/views/layouts/` Marionette Layouts
* `scripts/app.coffee`     Marionette Application
* `scripts/config.coffee`  Requirejs Config
* `scripts/main.js`        Initial Requirejs Loader
* `scripts/session.coffee` Model of Session
* `styles/`                LESS and CSS Styling
* `templates/`             Handlebars Templates
* `templates/helpers/`     Handlebars Helpers
* `index.html`             App's HTML Page

License
-------

This software is subject to the provisions of the GNU Affero General Public License Version 3.0 (AGPL). See license.txt for details. Copyright (c) 2013 Rice University