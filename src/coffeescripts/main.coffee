# Entry poiont for client-side app
require.config
  paths:
    jquery:     'vendor/jquery-2.0.3.min'
    underscore: 'vendor/lodash.min'
    angular:    'vendor/angular.min'
    angularUI:  'vendor/ui-utils.min'
  shim:
    underscore:
      deps: []
      exports: '_'
    angular:
      deps: []
      exports: 'angular'
    angularUI:
      deps: ['angular']
      exports: 'angularUI'

define (require, exports, module) ->

  juicerController = require 'controllers/juicer'
  juicerController.init()

