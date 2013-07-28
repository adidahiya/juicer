define (require) ->

  _         = require 'underscore'
  $         = require 'jquery'
  angular   = require 'angular'

  require 'filer'

  DEBUG               = false
  DEFAULT_ZOOM_LEVEL  = 50
  SCENE_TOP_PADDING   = 35
  DEFAULT_IMAGE_SIZE  = 100

  initAppModule = () ->

    appModule = angular.module 'juicer', []

    appModule.directive 'renderWindow', () ->
      restrict: 'E'
      link: ($scope, $element, attrs) ->
        $scope.rendererWidth  = parseInt $element.width()
        $scope.rendererHeight = parseInt $element.height()
        $scope.camera.xOffset = $scope.rendererWidth / 2
        $scope.camera.yOffset = $scope.rendererHeight / 2

        $element.mousedown (event) ->
          $scope.$apply () ->
            $scope.pan.isActive = true
            $scope.pan.xStart = event.pageX
            $scope.pan.yStart = event.pageY

        onMousemove = (event) =>
          if $scope.pan.isActive
            $scope.$apply () ->
              $scope.camera.xOffset += (event.pageX - $scope.pan.xStart) / 20
              $scope.camera.yOffset += (event.pageY - $scope.pan.yStart) / 20
              $scope.scrubberChange()

        $element.mousemove onMousemove

        $element.mouseup (event) => $scope.pan.isActive = false
        $element.mouseleave (event) => $scope.pan.isActive = false

    window.JuicerController = ($scope, $timeout) ->

      $scope.download = () ->
        images = _.map $scope.objects[1..], (obj) ->
          _.pick obj, 'name'
        frames = []
        for t in [$scope.timeStart...$scope.timeEnd]
          frame = {}
          for object in $scope.objects[1..]
            renderedProperties = $scope.getObjectStyle(object)
            frame[object.name] =
              left:   "#{renderedProperties.left - $scope.camera.xOffset}px"
              top:    "#{renderedProperties.top - $scope.camera.yOffset}px"
              width:  "#{renderedProperties.width}px"
              height: "#{renderedProperties.height}px"
          frames.push frame

        data =
          camera:
            width: $('#camera-view').width()
            height: $('#camera-view').height()
          images: images
          frames: frames

        $scope.jsonDump = JSON.stringify(data)
        filer = new Filer()
        filer.init
          persistent: true
        , (fs) =>
          filer.ls '/', (entries) -> console.log entries
          filer.ls '.', (entries) -> console.log entries
          filer.write 'juiceAnimation.json',
            data: $scope.jsonDump
            type: 'text/json'
            append: false
          , (fileEntry, fileWriter) =>
            console.log 'success', fileEntry, fileWriter
          , (error) =>
            console.log 'error', error
        , (error) =>
          console.log "unable to write to file system: ", error

      # Scene navigation
      # ----------------------------------------------------------------------
      $scope.zoomLevel = DEFAULT_ZOOM_LEVEL
      $scope.currentScale = 1

      $scope.zoom = () ->
        scale       = $scope.zoomLevel / DEFAULT_ZOOM_LEVEL
        halfWidth   = $scope.rendererWidth / 2
        halfHeight  = $scope.rendererHeight / 2

        xCenter = ($scope.camera.xOffset - halfWidth) * scale
        yCenter = ($scope.camera.yOffset - halfHeight) * scale
        $scope.camera.xOffset = xCenter + halfWidth
        $scope.camera.yOffset = yCenter + halfHeight
        $scope.currentScale = scale

      $scope.pan =
        isActive: false

      $scope.reset = () ->
        $scope.camera.xOffset = $scope.rendererWidth / 2
        $scope.camera.yOffset = $scope.rendererHeight / 2
        $scope.zoomLevel = DEFAULT_ZOOM_LEVEL
        $scope.currentScale = 1
        $scope.time = 0
        $scope.scrubberChange()

      # Timeline
      # ----------------------------------------------------------------------
      $scope.time       = 0
      $scope.timeStart  = 0
      $scope.timeEnd    = 300
      $scope.playSpeed  = 40

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
        $scope.playSpeed = $scope.playSpeed / factor
        if didPause
          $scope.play()

      $scope.visibleTicks = [$scope.timeStart...$scope.timeEnd]

      # Scene objects
      # ----------------------------------------------------------------------
      $scope.camera =
        name: "Camera"
        xOffset: 500
        yOffset: 250
        scale: $scope.currentScale
      $scope.objects = [$scope.camera]
      $scope.selectedObject = null

      $scope.properties = () ->
        _.keys(_.omit($scope.selectedObject, "name", "$$hashKey", "src"))

      $scope.getObjectStyle = (object) ->
        left:   $scope.currentScale * object.x + $scope.camera.xOffset
        top:    $scope.currentScale * object.y + $scope.camera.yOffset + SCENE_TOP_PADDING
        width:  $scope.currentScale * object.width
        height: $scope.currentScale * object.height

      $scope.getObjectNames = -> _.pluck $scope.objects, 'name'

      $scope.addObject = ->
        if $scope.newObjectName? and not ($scope.newObjectName in $scope.getObjectNames()) and $scope.newObjectSrc?
          newObject =
            name: $scope.newObjectName
            src: $scope.newObjectSrc
            width: DEFAULT_IMAGE_SIZE
            height: DEFAULT_IMAGE_SIZE
            x: -(DEFAULT_IMAGE_SIZE / 2)
            y: -(DEFAULT_IMAGE_SIZE / 2)
          $scope.objects.push newObject
          $scope.selectObject newObject
          $scope.newObjectName = null
          for i in [$scope.timeStart...$scope.timeEnd]
            $scope.frames[i].bindData(newObject.name, newObject)

      $scope.selectObject = (object) ->
        $scope.selectedObject = object

      $scope.isObjectSelected = (object) ->
        $scope.selectedObject is object

      $scope.frames =
        for i in [$scope.timeStart...$scope.timeEnd]
          # obj_name -> True if keyframe is at that time
          keys: {}
          # obj properties interpolated for point in time
          interpolatedValues: {}
          bindData: (name, object) ->
            @interpolatedValues[name] = _.clone(object)
          getData: (name) ->
            @interpolatedValues[name]

      # Initialize camera frames
      for i in [$scope.timeStart...$scope.timeEnd]
        $scope.frames[i].bindData($scope.camera.name, $scope.camera)

      # Look up interpolated values to show animated steps
      $scope.scrubberChange = () ->
        for object in $scope.objects
          objectValues = $scope.frames[$scope.time].getData(object.name)
          for prop in $scope.properties()
            object[prop] = parseFloat(objectValues[prop])

      $scope.setPropertyAtTime = (property, time, val) ->
        $scope.frames[time].getData($scope.selectedObject.name)[property] = val

      $scope.setObjectAtTime = (time, object) ->
        for property in $scope.properties()
          $scope.setPropertyAtTime property, time, object[property]

      $scope.addKeyframe = () ->
        unless $scope.selectedObject?
          $scope.error = "No object selected to keyframe."
          return
        $scope.setKeyFrame(parseInt($scope.time))

      $scope.removeKeyframe = (frames, time, name) ->
        time = parseInt(time)
        frame = frames[time]
        # Clear key frame
        delete frame.keys[name]

        # Re-interpolate neighbors
        forwardTime = $scope.findKeyFrame(time, $scope.timeEnd, 1, name, frames)
        if forwardTime is $scope.timeEnd
          # neighbor not found
          backTime = $scope.findKeyFrame(time, $scope.timeStart, -1, name, frames)
          if backTime is $scope.timeStart
            $scope.fill $scope.timeStart, $scope.timeEnd, 1
          else
            $scope.setKeyFrame(parseInt(backTime))
        else
            $scope.setKeyFrame(parseInt(forwardTime))

      $scope.findKeyFrame = (timeStart, timeEnd, timeStep, name, frames) ->
        until timeStart is timeEnd
          if frames[timeStart].keys[name]?
            break
          timeStart += timeStep
        return timeStart

      $scope.fill = (timeStart, timeEnd, timeStep) ->
        until timeStart is timeEnd
          $scope.setObjectAtTime timeStart, $scope.selectedObject
          timeStart += timeStep

      # Fill in all interpolated values based on frameStep
      $scope.interpolate = (timeStart, timeEnd, timeStep, name, frames) ->
        getDifference = (objectStart, objectEnd) ->
          difference = {}
          for property in $scope.properties()
            dProp = objectEnd[property] - objectStart[property]
            dT = timeEnd - timeStart
            difference[property] = parseFloat(dProp / dT)
          return difference
        objectStart = frames[timeStart].getData(name)
        objectEnd = frames[timeEnd].getData(name)
        objectDifference = getDifference(objectStart, objectEnd)

        t = 0
        until timeStart + t is timeEnd
          time = timeStart + t
          for property in $scope.properties()
            rv = parseFloat(objectStart[property]) + objectDifference[property] * t
            $scope.setPropertyAtTime property, time, rv.toFixed(3)
          t += timeStep

      $scope.setKeyFrame = (time) ->
        $scope.frames[time].keys[$scope.selectedObject.name] = true
        $scope.setObjectAtTime time, $scope.selectedObject

        runInterpolationWalk = (timeStart, timeBound, timeStep, name, frames) ->
          projection = timeStart + timeStep
          if $scope.timeStart <= projection <= $scope.timeEnd
            timeEnd = $scope.findKeyFrame(projection, timeBound, timeStep, name, frames)
            if timeEnd is timeBound
              $scope.fill timeStart, timeEnd, timeStep
            else
              $scope.interpolate timeStart, timeEnd, timeStep, name, frames

        name = $scope.selectedObject.name
        frames = $scope.frames

        runInterpolationWalk(time, $scope.timeStart - 1, -1, name, frames)
        runInterpolationWalk(time, $scope.timeEnd, 1, name, frames)

    # Initializes the controller
    window.JuicerController.$inject = ['$scope', '$timeout']


  # Public API
  # ---------------------------------------------------------------------------

  init: ->
    initAppModule()
    angular.bootstrap document, ['juicer']

