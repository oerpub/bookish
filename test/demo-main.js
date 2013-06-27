(function () {
  "use strict";

  require({
    baseUrl: '../scripts/',

    paths: {
      cs: 'libs/require/plugins/require-cs/cs',
      'coffee-script': 'libs/require/plugins/require-cs/coffee-script',
      jquery: 'libs/jquery',
      mockjax: 'libs/jquery-mockjax/jquery.mockjax'
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
