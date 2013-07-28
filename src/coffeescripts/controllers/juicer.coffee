define (require) ->

  _         = require 'underscore'
  $         = require 'jquery'
  angular   = require 'angular'

  DEBUG               = false
  MAX_ANIMATION_TIME  = 300
  DEFAULT_ZOOM_LEVEL  = 50
  SCENE_TOP_PADDING   = 35

  initAppModule = () ->

    appModule = angular.module 'juicer', []

    appModule.directive "renderWindow", () ->
      restrict: 'E'
      link: ($scope, $element, attrs) ->
        $scope.rendererWidth  = parseInt $element.width()
        $scope.rendererHeight = parseInt $element.height()
        $scope.xOffset = $scope.rendererWidth / 2
        $scope.yOffset = $scope.rendererHeight / 2

        $element.mousedown (event) ->
          $scope.$apply () ->
            $scope.pan.isActive = true
            $scope.pan.xStart = event.pageX
            $scope.pan.yStart = event.pageY

        onMousemove = (event) =>
          if $scope.pan.isActive
            $scope.$apply () ->
              $scope.xOffset += (event.pageX - $scope.pan.xStart) / 20
              $scope.yOffset += (event.pageY - $scope.pan.yStart) / 20
              $scope.scrubberChange()

        $element.mousemove onMousemove

        $element.mouseup (event) => $scope.pan.isActive = false
        $element.mouseleave (event) => $scope.pan.isActive = false

    window.JuicerController = ($scope, $timeout) ->

      # Scene navigation
      # ----------------------------------------------------------------------
      $scope.zoomLevel = DEFAULT_ZOOM_LEVEL
      $scope.xOffset = 500
      $scope.yOffset = 250
      $scope.currentScale = 1

      $scope.zoom = () ->
        scale       = $scope.zoomLevel / DEFAULT_ZOOM_LEVEL
        halfWidth   = $scope.rendererWidth / 2
        halfHeight  = $scope.rendererHeight / 2

        xCenter = ($scope.xOffset - halfWidth) * scale
        yCenter = ($scope.yOffset - halfHeight) * scale
        $scope.xOffset = xCenter + halfWidth
        $scope.yOffset = yCenter + halfHeight
        $scope.currentScale = scale

      $scope.pan =
        isActive: false

      # Timeline
      # ----------------------------------------------------------------------
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

      $scope.isPaused = true
      $scope.play = () ->
        $scope.isPaused = false
        $scope.playInterval = setInterval () ->
          $scope.$apply () ->
            $scope.time = ($scope.time + 1) % $scope.timeEnd
            $scope.scrubberChange()
        , $scope.playSpeed
      $scope.pause = () ->
        $scope.isPaused = true
        clearInterval $scope.playInterval

      $scope.setPlaySpeed = (factor) ->
        unless $scope.isPaused
          $scope.pause()
          didPause = true
        $scope.playSpeed *= factor
        if didPause
          $scope.play()

      $scope.visibleTicks =
        for i in [$scope.timeStart..$scope.timeEnd]
          value: i

      # Scene objects
      # ----------------------------------------------------------------------
      $scope.objects = []
      $scope.selectedObject = null

      $scope.getObjectStyle = (object) ->
        left:   $scope.currentScale * object.x + $scope.xOffset
        top:    $scope.currentScale * object.y + $scope.yOffset + SCENE_TOP_PADDING
        width:  $scope.currentScale * object.width
        height: $scope.currentScale * object.height

      $scope.addObject = ->
        if $scope.newObjectName? and $scope.newObjectSrc?
          newObject =
            name: $scope.newObjectName
            src: $scope.newObjectSrc
            width: 100
            height: 100
            x: -50
            y: -50
          $scope.objects.push newObject
          $scope.selectObject newObject
          $scope.newObjectName = null
          for i in [0..MAX_ANIMATION_TIME]
            $scope.frames[i].interpolatedValues[newObject.name] = _.clone(newObject)

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

      # Look up interpolated values to show animated steps
      $scope.scrubberChange = () ->
        for object in $scope.objects
          objectValues = \
            $scope.frames[$scope.time].interpolatedValues[object.name]
          for prop in $scope.keyframedProperties
            object[prop] = parseFloat(objectValues[prop])

      $scope.setPropertyAtTime = (property, time, val) ->
        $scope.frames[time].interpolatedValues[$scope.selectedObject.name][property] = val

      $scope.setObjectAtTime = (time, object) ->
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
          if frames[timeStart].keys[name]?
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
        getDifference = (objectStart, objectEnd) ->
          difference = {}
          for property in $scope.keyframedProperties
            dProp = objectEnd[property] - objectStart[property]
            dT = timeEnd - timeStart
            difference[property] = parseFloat(dProp / dT)
          return difference
        objectStart = frames[timeStart].interpolatedValues[name]
        objectEnd = frames[timeEnd].interpolatedValues[name]
        objectDifference = getDifference(objectStart, objectEnd)

        t = 0
        while timeStart + t isnt timeEnd
          time = timeStart + t
          for property in $scope.keyframedProperties
            rv = parseFloat(objectStart[property]) + objectDifference[property] * t
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

