var requirejs = require('requirejs');

requirejs.config({
  paths: {
    cs: __dirname + '/../node_modules/cs/cs',
    mock: __dirname + '/data'
  }
});

requirejs(['cs!./all-mock-data'], function(jsonData) {
  console.log(JSON.stringify(jsonData));
});
