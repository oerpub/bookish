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
