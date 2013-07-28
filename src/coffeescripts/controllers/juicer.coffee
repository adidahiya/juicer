define (require) ->

  _         = require 'underscore'
  angular   = require 'angular'

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

    # Initializes the controller
    window.JuicerController.$inject = ['$scope']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

