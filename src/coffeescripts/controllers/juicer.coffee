define (require) ->

  _         = require 'underscore'
  angular   = require 'angular'

  DEBUG = true

  initAppModule = () ->

    appModule = angular.module 'juicer', []

    # Get services from factories
    # Initialize directives, etc

    window.JuicerController = ($scope) ->

      $scope.foo = 5

    # Initializes the controller
    window.JuicerController.$inject = ['$scope']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

