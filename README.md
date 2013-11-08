# Development and Building

Below are instructions for building the book editor yourself and a layout
of how the code is organized.

## Building Yourself

### With Vagrant
* install [virtualbox](https://www.virtualbox.org/wiki/Downloads)
* install [vagrant](http://downloads.vagrantup.com/)
* clone [github book editor](https://github.com/oerpub/github-bookeditor) repo to somewhere
* inside the repo run `vagrant up` from a command line
  * there is currently a bug in the build that makes it not run fully on the first pass, the workaround is to log into the vm after running `vagrant up` with `vagrant ssh`, then go into `/vagrant` and run `npm install`. that will finish the build for you
* vagrant will take a while to configure the new vm when its done you will be able to hit "33.33.33.10" in a web browser and see the editor

### Manually
1. Download and extract (if necessary)
2. Run `npm install` or just `bower install` in the directory to download and install dependencies
3. Start up a webserver


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

This software is subject to the provisions of the GNU Affero General Public License Version 3.0 (AGPL). See license.txt for details. 

Copyright
---------
Code contributed by Rice University employees and contractors is Copyright (c) 2013 Rice University 
Code contributed by contractors to the OERPUB project is Copyright (c) 2013 Kathi Fletcher

Funding
-------
Development by the OERPUB project was funded by the Shuttleworth Foundation, through a fellowship and project funds granted to Kathi Fletcher. 
