(function () {
  "use strict";

  /* Load relative URLs based on the CSS file containing url() instead of the root LESS file */
  window.less = {
    relativeUrls: true
  };

  require({
    baseUrl: '../scripts/',

    paths: {
      cs: '../bower_components/require-cs/cs',
      'coffee-script': '../bower_components/coffee-script/index',
      jquery: '../bower_components/jquery/jquery',
      mockjax: '../bower_components/jquery-mockjax/jquery.mockjax'
    },

    shim: {
      mockjax: ['jquery']
    }
  }, ['cs!../test/demo-mock']);

  /* If an error occurs in requirejs then change the loading HTML. */
  require.onError = function (err) {
    var title = document.getElementById('loading-text'),
        bar = document.getElementById('loading-bar');

    if (title) {
      title.innerHTML = 'Loading failed.';
    }

    if (bar) {
      bar.className = 'bar bar-danger';
    }

    throw err;
  };

})();
