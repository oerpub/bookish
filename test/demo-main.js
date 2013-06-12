require({
  paths: {
    cs: '../scripts/libs/require/plugins/require-cs/cs',
    'coffee-script': '../scripts/libs/require/plugins/require-cs/coffee-script',
    jquery: '../scripts/libs/jquery',
    mockjax: '../scripts/libs/jquery-mockjax/jquery.mockjax'
  },
  
  shim: {
    mockjax: ['jquery']
  }
}, ['cs!demo-mock']);
