# Development and Building

Below are instructions for building the book editor yourself and a layout
of how the code is organized.

## Building Yourself

1. Download and extract (if necessary)
2. Run `npm install` or just `bower install` in the directory to download and install dependencies
3. Start up a webserver by running `npm run server` (uses `http-server`)


## Building Documentation

Documentation is built using `docco`.

    find . -name "*.coffee" | grep -v './bower_components/' | grep -v './node_modules' | xargs ./node_modules/docco/bin/docco

Check the `./docs` directory to read through the different modules.

## Directory Layout

* `scripts/collections/`   Backbone Collections
* `scripts/configs/`       App and 3rd party configs
* `scripts/controllers/`   Marionette Controllers
* `scripts/helpers/`       Miscellaneous helper functions
* `scripts/models/`        Backbone Models and Marionette Modules
* `scripts/nls/`           Internationalized strings
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
* `test/`                  Testable mock data and scripts
* `index.html`             App's HTML Page

License
-------

This software is subject to the provisions of the GNU Affero General Public License Version 3.0 (AGPL). See license.txt for details. Copyright (c) 2013 Rice University
