# Entry poiont for client-side app
require.config
  paths:
    jquery:     'vendor/jquery-2.0.3.min'
    underscore: 'vendor/lodash.min'
    angular:    'vendor/angular.min'
    filer:      'vendor/filer.min'
  shim:
    underscore:
      deps: []
      exports: '_'
    angular:
      deps: []
      exports: 'angular'
    filer:
      deps: []
      exports: 'filer'

define (require, exports, module) ->

  juicerController = require 'controllers/juicer'
  juicerController.init()

