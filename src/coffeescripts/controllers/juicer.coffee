define (require) ->

  _         = require 'underscore'
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

      $scope.objects = []
      $scope.selectedObject = null

      $scope.addObject = ->
        if $scope.object?
          object =
            name: $scope.object
          $scope.objects.push object
          $scope.selectObject object
          $scope.object = null

      $scope.selectObject = (object) ->
        $scope.selectedObject = object

      $scope.isObjectSelected = (object) ->
        $scope.selectedObject is object

    # Initializes the controller
    window.JuicerController.$inject = ['$scope']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

