(function () {
  "use strict";

  require({
    paths: {
      cs: 'libs/require/plugins/require-cs/cs',
      'coffee-script': 'libs/require/plugins/require-cs/coffee-script'
    }
  }, ['cs!config']);

  /* If an error occurs in requirejs then change the loading HTML. */
  require.onError = function (err) {
    var title = document.getElementById('loading-text'),
        bar = document.getElementById('loading-bar');

    if (title) {
      title.innerHTML = 'Loading failed.<br />Please try again later.';
    }

    if (bar) {
      bar.className = 'bar bar-danger';
    }
    
    throw err;
  };

})();
