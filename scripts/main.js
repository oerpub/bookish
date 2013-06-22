(function() {

  require({
    paths: {
      cs: 'libs/require/plugins/require-cs/cs',
      'coffee-script': 'libs/require/plugins/require-cs/coffee-script'
    }
  }, ['cs!config']);

  /* If an error occurs in requirejs then change the loading HTML. */
  require.onError = function(err) {
    "use strict";
    var title = document.getElementById('loading-text'),
        progress = document.getElementById('loading-progress');

    if (title != null) {
      title.textContent = 'Loading failed. Please try again in a bit.';
    }
    if (progress != null) {
      progress.className = 'progress progress-danger';
    }
  };

}) ();
