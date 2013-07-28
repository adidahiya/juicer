define (require) ->

  _         = require 'underscore'
  $         = require 'jquery'
  angular   = require 'angular'

  DEBUG = true
  MAX_ANIMATION_TIME = 300

  initAppModule = () ->

    appModule = angular.module 'juicer', []

    appModule.directive "renderWindow", () ->
      restrict: 'E'
      link: ($scope, $element, attrs) ->
        $scope.rendererWidth = $element.width()
        $scope.rendererHeight = $element.height()

    appModule.directive "renderedObject", () ->
      restrict: 'E'
      link: ($scope, $element, attrs) ->
        render = () ->
          $element.css
            left:   $scope.object.x * $scope.currentScale + $scope.xOffset
            top:    $scope.object.y * $scope.currentScale + $scope.yOffset
            width:  $scope.object.width * $scope.currentScale
            height: $scope.object.height * $scope.currentScale

        $scope.$watch "object.x", render
        $scope.$watch "object.y", render
        $scope.$watch "object.width", render
        $scope.$watch "object.height", render
        $scope.$watch "currentScale", render
        $scope.$watch "xOffset", render
        $scope.$watch "yOffset", render

    window.JuicerController = ($scope, $timeout) ->

      # Scene
      $scope.zoomLevel = 0
      # TODO: make not static
      $scope.xOffset = 300
      $scope.yOffset = 200
      $scope.currentScale = 1

      $scope.rescale = (scale) ->
        halfWidth   = $scope.rendererWidth / 2
        halfHeight  = $scope.rendererHeight / 2

        xCenter = ($scope.xOffset - halfWidth) * scale
        yCenter = ($scope.yOffset - halfHeight) * scale
        $scope.xOffset = xCenter + halfWidth
        $scope.yOffset = yCenter + halfHeight
        $scope.currentScale *= scale

      # Timeline
      $scope.keyframedProperties = [
        'width'
        'height'
        'x'
        'y'
      ]
      $scope.time = 0
      $scope.timeStart = 0
      $scope.timeEnd = 49
      $scope.playSpeed = 200

      $scope.playInterval = null
      $scope.isPaused = true
      $scope.play = () ->
        $scope.isPaused = false
        stopInterval = $timeout(`function incTime() {
          $scope.time = ($scope.time + 1) % $scope.timeEnd;
          $scope.playInterval = $timeout(incTime, $scope.playSpeed);
        }`, $scope.playSpeed)
      $scope.pause = () ->
        $scope.isPaused = true
        $timeout.cancel $scope.playInterval

      $scope.visibleTicks =
        for i in [$scope.timeStart..$scope.timeEnd]
          value: i

      $scope.objects = []
      $scope.selectedObject = null

      $scope.addObject = ->
        if $scope.object?
          object =
            name: $scope.object
            width: 10
            height: 10
            x: 10
            y: 10
          $scope.objects.push object
          $scope.selectObject object
          $scope.object = null
          for i in [0..MAX_ANIMATION_TIME]
            $scope.frames[i].interpolatedValues[object.name] = _.clone(object)

      $scope.selectObject = (object) ->
        $scope.selectedObject = object

      $scope.isObjectSelected = (object) ->
        $scope.selectedObject is object

      $scope.frames =
        for i in [0..MAX_ANIMATION_TIME]
          # obj_name -> True if keyframe is at that time
          keys: {}
          # obj properties interpolated for point in time
          interpolatedValues: {}

      $scope.scrubberChange = () ->
        for object in $scope.objects
          for property in $scope.keyframedProperties
            object[property] = parseFloat($scope.frames[$scope.time].interpolatedValues[object.name][property])
        if $scope.selectedObject?
          for property in $scope.keyframedProperties
            $scope.selectedObject[property] = parseFloat($scope.frames[$scope.time].interpolatedValues[$scope.selectedObject.name][property])

      $scope.setPropertyAtTime = (property, time, val) ->
        console.log "setPropertyAtTime", property, time, val
        $scope.frames[time].interpolatedValues[$scope.selectedObject.name][property] = val

      $scope.setObjectAtTime = (time, object) ->
        console.log "setObjectAtTime", time, object
        for property in $scope.keyframedProperties
          $scope.setPropertyAtTime property, time, object[property]

      $scope.addKeyframe = () ->
        unless $scope.selectedObject?
          $scope.error = "No object selected to keyframe."
          return
        $scope.setKeyFrame(parseInt($scope.time))

      $scope.removeKeyframe = () ->
        $scope.time = parseInt($scope.time)
        frame = $scope.frames[$scope.time]
        # Clear key frame
        delete frame.keys[$scope.selectedObject.name]

        # Re-interpolate neighbors
        forwardTime = $scope.findKeyFrame($scope.time, true, $scope.selectedObject.name, $scope.frames)
        if forwardTime is MAX_ANIMATION_TIME
          # neighbor not found
          backTime = $scope.findKeyFrame($scope.time, false, $scope.selectedObject.name, $scope.frames)
          if backTime isnt 0
            $scope.setKeyFrame(parseInt(backTime))
          else
            $scope.fill 0, MAX_ANIMATION_TIME, 1
        else
            $scope.setKeyFrame(parseInt(forwardTime))

      $scope.findKeyFrame = (timeStart, timeEnd, timeStep, name, frames) ->
        while timeStart isnt timeEnd
          if frames[timeStart].keys[name]
            break
          timeStart += timeStep
        return timeStart
      
      $scope.fill = (timeStart, timeEnd, timeStep) ->
        while timeStart isnt timeEnd
          $scope.setObjectAtTime timeStart, $scope.selectedObject
          timeStart += timeStep
        $scope.setObjectAtTime timeStart, $scope.selectedObject

      # Fill in all interpolated values based on frameStep
      $scope.interpolate = (timeStart, timeEnd, timeStep, name, frames) ->
        console.log "interpolate", timeEnd
        getDifference = (objectStart, objectEnd) ->
          console.log "getDifference", objectStart, objectEnd
          difference = {}
          for property in $scope.keyframedProperties
            dProp = objectEnd[property] - objectStart[property]
            dT = timeEnd - timeStart
            difference[property] = parseFloat(dProp / dT)
          console.log "difference", difference
          return difference
        objectStart = frames[timeStart].interpolatedValues[name]
        objectEnd = frames[timeEnd].interpolatedValues[name]
        objectDifference = getDifference(objectStart, objectEnd)

        t = 0
        while timeStart + t isnt timeEnd
          time = timeStart + t
          for property in $scope.keyframedProperties
            rv = parseFloat(objectStart[property]) + objectDifference[property] * t
            console.log "!", parseFloat(objectStart[property]), objectDifference[property] * t
            $scope.setPropertyAtTime property, time, rv.toFixed(3)
          t += timeStep

      $scope.setKeyFrame = (time) ->
        $scope.frames[time].keys[$scope.selectedObject.name] = true
        $scope.setObjectAtTime time, $scope.selectedObject

        runInterpolationWalk = (timeStart, timeBound, timeStep, name, frames) ->
          timeEnd = $scope.findKeyFrame(timeStart + timeStep, timeBound, timeStep, name, frames)
          if timeEnd is timeBound
            $scope.fill timeStart, timeEnd, timeStep
          else
            $scope.interpolate timeStart, timeEnd, timeStep, name, frames

        name = $scope.selectedObject.name
        frames = $scope.frames

        runInterpolationWalk(time, 0, -1, name, frames)
        runInterpolationWalk(time, MAX_ANIMATION_TIME, 1, name, frames)

    # Initializes the controller
    window.JuicerController.$inject = ['$scope', '$timeout']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

