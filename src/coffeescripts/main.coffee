# Entry poiont for client-side app
require.config
  paths:
    jquery:     'vendor/jquery-2.0.3.min'
    underscore: 'vendor/lodash.min'
    angular:    'vendor/angular.min'
    angularUI:  'vendor/ui-utils.min'
    jscrollpane: 'vendor/jscrollpane'
    mousewheel: 'vendor/mousewheel'
  shim:
    underscore:
      deps: []
      exports: '_'
    mousewheel:
      deps: ['jquery']
      exports: 'mousewheel'
    jscrollpane:
      deps: ['jquery']
      exports: 'jscrollpane'
    angular:
      deps: []
      exports: 'angular'
    angularUI:
      deps: ['angular']
      exports: 'angularUI'

define (require, exports, module) ->

  juicerController = require 'controllers/juicer'
  juicerController.init()

