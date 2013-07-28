define (require) ->

  _         = require 'underscore'
  $         = require 'jquery'
  mousewheel = require 'mousewheel'
  jscroll   = require 'jscrollpane'
  angular   = require 'angular'
  angularUI = require 'angularUI'

  DEBUG = true

  initAppModule = () ->

    appModule = angular.module 'juicer', []

    # Get services from factories
    # Initialize directives, etc

    window.JuicerController = ($scope) ->

      $scope.timeStart = 0
      $scope.timeEnd = 49

      $scope.visibleTicks =
        for i in [$scope.timeStart..$scope.timeEnd]
          value: i

      $scope.layers = []
      $scope.selectedLayer = null

      $scope.addLayer = ->
        if $scope.layer?
          layer =
            name: $scope.layer
          $scope.layers.push layer
          $scope.selectLayer layer
          $scope.layer = null

      $scope.selectLayer = (layer) ->
        $scope.selectedLayer = layer

      $scope.isLayerSelected = (layer) ->
        $scope.selectedLayer is layer

      jQuery(document).bind 'DOMMouseScroll mousewheel', (e, delta) ->
        console.log "fire", e, delta

    # Initializes the controller
    window.JuicerController.$inject = ['$scope']



  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

