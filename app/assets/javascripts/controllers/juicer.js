// Generated by CoffeeScript 1.4.0
(function() {

  define(function(require) {
    var DEBUG, KEYFRAMED_PROPERTIES, MAX_ANIMATION_TIME, angular, initAppModule, _;
    _ = require('underscore');
    angular = require('angular');
    DEBUG = true;
    MAX_ANIMATION_TIME = 300;
    KEYFRAMED_PROPERTIES = ['width', 'height', 'x', 'y'];
    initAppModule = function() {
      var appModule;
      appModule = angular.module('juicer', []);
      window.JuicerController = function($scope) {
        var i;
        $scope.time = 0;
        $scope.timeStart = 0;
        $scope.timeEnd = 49;
        $scope.visibleTicks = (function() {
          var _i, _ref, _ref1, _results;
          _results = [];
          for (i = _i = _ref = $scope.timeStart, _ref1 = $scope.timeEnd; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; i = _ref <= _ref1 ? ++_i : --_i) {
            _results.push({
              value: i
            });
          }
          return _results;
        })();
        $scope.objects = [];
        $scope.selectedObject = null;
        $scope.addObject = function() {
          var object;
          if ($scope.object != null) {
            object = {
              name: $scope.object,
              width: 10,
              height: 10,
              x: 10,
              y: 10
            };
            $scope.objects.push(object);
            $scope.selectObject(object);
            return $scope.object = null;
          }
        };
        $scope.selectObject = function(object) {
          return $scope.selectedObject = object;
        };
        $scope.isObjectSelected = function(object) {
          return $scope.selectedObject === object;
        };
        $scope.frames = (function() {
          var _i, _results;
          _results = [];
          for (i = _i = 0; 0 <= MAX_ANIMATION_TIME ? _i <= MAX_ANIMATION_TIME : _i >= MAX_ANIMATION_TIME; i = 0 <= MAX_ANIMATION_TIME ? ++_i : --_i) {
            _results.push({
              keys: {},
              interpolatedValues: {}
            });
          }
          return _results;
        })();
        $scope.addKeyframe = function() {
          var frame, runInterpolationWalk;
          if ($scope.selectedObject == null) {
            $scope.error = "No object selected to keyframe.";
            return;
          }
          $scope.time = parseInt($scope.time);
          frame = $scope.frames[$scope.time];
          frame.keys[$scope.selectedObject.name] = true;
          runInterpolationWalk = function(isForward) {
            var frameRunner, frameSteps, hasSeenTargetFrames, key, prevFrameRunner, targetFrame, time, timeBound, timeDiff, timeStep, _i, _len, _results;
            timeStep = isForward ? 1 : -1;
            timeBound = isForward ? MAX_ANIMATION_TIME : 0;
            time = $scope.time + timeStep;
            frameRunner = $scope.frames[time];
            hasSeenTargetFrames = true;
            while (!frameRunner.keys[$scope.selectedObject.name]) {
              if (time === timeBound) {
                hasSeenTargetFrames = false;
                break;
              }
              time += timeStep;
              frameRunner = $scope.frames[time];
            }
            debugger;
            if (hasSeenTargetFrames) {
              targetFrame = frameRunner.interpolatedValues[$scope.selectedObject.name];
              frameSteps = {};
              timeDiff = $scope.time - time;
              for (_i = 0, _len = KEYFRAMED_PROPERTIES.length; _i < _len; _i++) {
                key = KEYFRAMED_PROPERTIES[_i];
                frameSteps[key] = $scope.selectedObject[key] - prevKeyframe[key];
                if (isForward) {
                  frameSteps[key] *= -1;
                }
              }
              _results = [];
              while (time !== $scope.time) {
                time -= timeStep;
                frameRunner = $scope.frames[time];
                prevFrameRunner = $scope.frames[time + timeStep];
                _results.push((function() {
                  var _j, _len1, _results1;
                  _results1 = [];
                  for (_j = 0, _len1 = KEYFRAMED_PROPERTIES.length; _j < _len1; _j++) {
                    key = KEYFRAMED_PROPERTIES[_j];
                    _results1.push(frameRunner.interpolatedValues[key] = prevFrameRunner.interpolatedValues[key] + frameSteps[key]);
                  }
                  return _results1;
                })());
              }
              return _results;
            }
          };
          if ($scope.time > $scope.timeStart) {
            runInterpolationWalk(false);
          }
          if ($scope.selectedObject.furthestFrameTime < $scope.time) {
            return $scope.selectedObject.furthestFrameTime = $scope.time;
          } else {
            return runInterpolationWalk(true);
          }
        };
        return $scope.removeKeyframe = function() {
          var frame;
          frame = $scope.frames[$scope.time];
          return delete frame.keys[$scope.selectedObject.name];
        };
      };
      return window.JuicerController.$inject = ['$scope'];
    };
    return {
      init: function() {
        initAppModule();
        return angular.bootstrap(document, ['juicer']);
      }
    };
  });

}).call(this);
