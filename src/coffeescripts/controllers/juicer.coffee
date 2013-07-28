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
        if $scope.selectedObject?
          for property in $scope.keyframedProperties
            $scope.selectedObject[property] = parseFloat($scope.frames[$scope.time].interpolatedValues[$scope.selectedObject.name][property])

      $scope.setPropertyAtFrame = (property, time, val) ->
        console.log "setPropertyAtFrame", property, time, val
        $scope.frames[time].interpolatedValues[$scope.selectedObject.name][property] = val

      $scope.setObjectAtFrame = (time, object) ->
        console.log "setPropertyAtFrame", time, object
        for property in $scope.keyframedProperties
          $scope.setPropertyAtFrame property, time, object[property]

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
        forwardTime = $scope.findNextFrameTime($scope.time, true, $scope.selectedObject.name)
        if forwardTime is MAX_ANIMATION_TIME
          # neighbor not found
          backTime = $scope.findNextFrameTime($scope.time, false, $scope.selectedObject.name)
          if backTime isnt 0
            $scope.setKeyFrame(parseInt(backTime))
          else
            $scope.fill 0, MAX_ANIMATION_TIME, 1
        else
            $scope.setKeyFrame(parseInt(forwardTime))

      $scope.findNextFrameTime = (time, isForward, name) ->
        TIME_STEP  = if isForward then 1 else -1
        TIME_BOUND = if isForward then MAX_ANIMATION_TIME else 0
        frameRunner = $scope.frames[time]
        while not frameRunner.keys[name]
          if time is TIME_BOUND
            break
          time += TIME_STEP
          frameRunner = $scope.frames[time]
        return time
      
      $scope.fill = (start, end, step) ->
        while start isnt end
          $scope.setObjectAtFrame start, $scope.selectedObject
          start += step
        $scope.setObjectAtFrame start, $scope.selectedObject

      $scope.setKeyFrame = (time) ->

        runInterpolationWalk = (scope_time, isForward) ->
          TIME_STEP  = if isForward then 1 else -1
          TIME_BOUND = if isForward then MAX_ANIMATION_TIME else 0

          getFrameSteps = (time, targetFrame) ->
            # Calculate interpolation step between targetFrame and current
            frameSteps = {}
            timeDiff = scope_time - time
            for property in $scope.keyframedProperties
              frameSteps[property] = ($scope.selectedObject[property] - targetFrame[property]) / timeDiff
              # Invert if going forward
              if isForward
                frameSteps[property] *= -1
            return frameSteps

          frameRunner = $scope.frames[scope_time + TIME_STEP]
          nextTime = $scope.findNextFrameTime(scope_time + TIME_STEP, isForward, $scope.selectedObject.name)

          if nextTime is TIME_BOUND
            $scope.fill scope_time, TIME_BOUND, TIME_STEP
          else
            frameSteps = getFrameSteps(nextTime, frameRunner.interpolatedValues[$scope.selectedObject.name])
            # Fill in all interpolated values based on frameStep
            console.log "scope_time", scope_time
            while nextTime isnt scope_time
              nextTime -= TIME_STEP
              frameRunner     = $scope.frames[nextTime]
              prevFrameRunner = $scope.frames[nextTime + TIME_STEP]
              for property in $scope.keyframedProperties
                name = $scope.selectedObject.name
                rv = parseFloat(prevFrameRunner.interpolatedValues[name][property]) + parseFloat(frameSteps[property])
                $scope.setPropertyAtFrame property, nextTime, rv.toFixed(3)

        frame = $scope.frames[time]
        frame.keys[$scope.selectedObject.name] = true

        for property in $scope.keyframedProperties
          $scope.frames[time].interpolatedValues[$scope.selectedObject.name][property] = $scope.selectedObject[property]

        # Walk backwards to interpolate values
        if time > $scope.timeStart
          runInterpolationWalk(time, false)
          console.log $scope.frames

        # Update furthestFrameTime for this object
        if $scope.selectedObject.furthestFrameTime < time
          $scope.selectedObject.furthestFrameTime = time
        else
          # Walk forwards to interpolate values, too
          runInterpolationWalk(time, true)
          console.log $scope.frames

    # Initializes the controller
    window.JuicerController.$inject = ['$scope', '$timeout']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

