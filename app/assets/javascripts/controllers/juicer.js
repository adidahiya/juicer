// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require) {
    var $, DEBUG, MAX_ANIMATION_TIME, angular, initAppModule, _;
    _ = require('underscore');
    $ = require('jquery');
    angular = require('angular');
    DEBUG = true;
    MAX_ANIMATION_TIME = 300;
    initAppModule = function() {
      var appModule;
      appModule = angular.module('juicer', []);
      appModule.directive("renderWindow", function() {
        return {
          restrict: 'E',
          link: function($scope, $element, attrs) {
            $scope.rendererWidth = $element.width();
            return $scope.rendererHeight = $element.height();
          }
        };
      });
      appModule.directive("renderedObject", function() {
        return {
          restrict: 'E',
          link: function($scope, $element, attrs) {
            var render;
            render = function() {
              return $element.css({
                left: $scope.object.x * $scope.currentScale + $scope.xOffset,
                top: $scope.object.y * $scope.currentScale + $scope.yOffset,
                width: $scope.object.width * $scope.currentScale,
                height: $scope.object.height * $scope.currentScale
              });
            };
            $scope.$watch("object.x", render);
            $scope.$watch("object.y", render);
            $scope.$watch("object.width", render);
            $scope.$watch("object.height", render);
            $scope.$watch("currentScale", render);
            $scope.$watch("xOffset", render);
            return $scope.$watch("yOffset", render);
          }
        };
      });
      window.JuicerController = function($scope, $timeout) {
        var i;
        $scope.zoomLevel = 0;
        $scope.xOffset = 300;
        $scope.yOffset = 200;
        $scope.currentScale = 1;
        $scope.rescale = function(scale) {
          var halfHeight, halfWidth, xCenter, yCenter;
          halfWidth = $scope.rendererWidth / 2;
          halfHeight = $scope.rendererHeight / 2;
          xCenter = ($scope.xOffset - halfWidth) * scale;
          yCenter = ($scope.yOffset - halfHeight) * scale;
          $scope.xOffset = xCenter + halfWidth;
          $scope.yOffset = yCenter + halfHeight;
          return $scope.currentScale *= scale;
        };
        $scope.keyframedProperties = ['width', 'height', 'x', 'y'];
        $scope.time = 0;
        $scope.timeStart = 0;
        $scope.timeEnd = 49;
        $scope.playSpeed = 200;
        $scope.playInterval = null;
        $scope.isPaused = true;
        $scope.play = function() {
          var stopInterval;
          $scope.isPaused = false;
          return stopInterval = $timeout(function incTime() {
          $scope.time = ($scope.time + 1) % $scope.timeEnd;
          $scope.playInterval = $timeout(incTime, $scope.playSpeed);
        }, $scope.playSpeed);
        };
        $scope.pause = function() {
          $scope.isPaused = true;
          return $timeout.cancel($scope.playInterval);
        };
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
          var object, _i, _results;
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
            $scope.object = null;
            _results = [];
            for (i = _i = 0; 0 <= MAX_ANIMATION_TIME ? _i <= MAX_ANIMATION_TIME : _i >= MAX_ANIMATION_TIME; i = 0 <= MAX_ANIMATION_TIME ? ++_i : --_i) {
              _results.push($scope.frames[i].interpolatedValues[object.name] = _.clone(object));
            }
            return _results;
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
        $scope.scrubberChange = function() {
          var property, _i, _len, _ref, _results;
          if ($scope.selectedObject != null) {
            _ref = $scope.keyframedProperties;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              property = _ref[_i];
              _results.push($scope.selectedObject[property] = parseFloat($scope.frames[$scope.time].interpolatedValues[$scope.selectedObject.name][property]));
            }
            return _results;
          }
        };
        $scope.setPropertyAtFrame = function(property, time, val) {
          console.log("setPropertyAtFrame", property, time, val);
          return $scope.frames[time].interpolatedValues[$scope.selectedObject.name][property] = val;
        };
        $scope.setObjectAtFrame = function(time, object) {
          var property, _i, _len, _ref, _results;
          console.log("setPropertyAtFrame", time, object);
          _ref = $scope.keyframedProperties;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            property = _ref[_i];
            _results.push($scope.setPropertyAtFrame(property, time, object[property]));
          }
          return _results;
        };
        $scope.addKeyframe = function() {
          if ($scope.selectedObject == null) {
            $scope.error = "No object selected to keyframe.";
            return;
          }
          return $scope.setKeyFrame($scope.time);
        };
        $scope.removeKeyframe = function() {
          var backTime, forwardTime, frame;
          $scope.time = parseInt($scope.time);
          frame = $scope.frames[$scope.time];
          delete frame.keys[$scope.selectedObject.name];
          forwardTime = $scope.findNextFrameTime($scope.time, true, $scope.selectedObject.name);
          if (forwardTime === MAX_ANIMATION_TIME) {
            backTime = $scope.findNextFrameTime($scope.time, false, $scope.selectedObject.name);
            if (backTime !== 0) {
              return $scope.setKeyFrame(backTime);
            } else {
              return $scope.fill(0, MAX_ANIMATION_TIME, 1);
            }
          } else {
            return $scope.setKeyFrame(forwardTime);
          }
        };
        $scope.findNextFrameTime = function(time, isForward, name) {
          var TIME_BOUND, TIME_STEP, frameRunner;
          TIME_STEP = isForward ? 1 : -1;
          TIME_BOUND = isForward ? MAX_ANIMATION_TIME : 0;
          frameRunner = $scope.frames[time];
          while (!frameRunner.keys[name]) {
            if (time === TIME_BOUND) {
              break;
            }
            time += TIME_STEP;
            frameRunner = $scope.frames[time];
          }
          return time;
        };
        $scope.fill = function(start, end, step) {
          while (start !== end) {
            $scope.setObjectAtFrame(start, $scope.selectedObject);
            start += step;
          }
          return $scope.setObjectAtFrame(start, $scope.selectedObject);
        };
        return $scope.setKeyFrame = function(time) {
          var frame, property, runInterpolationWalk, _i, _len, _ref;
          $scope.time = parseInt(time);
          frame = $scope.frames[$scope.time];
          frame.keys[$scope.selectedObject.name] = true;
          _ref = $scope.keyframedProperties;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            property = _ref[_i];
            $scope.frames[$scope.time].interpolatedValues[$scope.selectedObject.name][property] = $scope.selectedObject[property];
          }
          runInterpolationWalk = function(scope_time, isForward) {
            var TIME_BOUND, TIME_STEP, frameRunner, frameSteps, getFrameSteps, name, nextTime, prevFrameRunner, rv, _results;
            TIME_STEP = isForward ? 1 : -1;
            TIME_BOUND = isForward ? MAX_ANIMATION_TIME : 0;
            getFrameSteps = function(time, targetFrame) {
              var frameSteps, timeDiff, _j, _len1, _ref1;
              frameSteps = {};
              timeDiff = scope_time - time;
              _ref1 = $scope.keyframedProperties;
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                property = _ref1[_j];
                frameSteps[property] = ($scope.selectedObject[property] - targetFrame[property]) / timeDiff;
                if (isForward) {
                  frameSteps[property] *= -1;
                }
              }
              return frameSteps;
            };
            frameRunner = $scope.frames[scope_time + TIME_STEP];
            nextTime = $scope.findNextFrameTime(scope_time + TIME_STEP, isForward, $scope.selectedObject.name);
            if (nextTime === TIME_BOUND) {
              return $scope.fill(scope_time, TIME_BOUND, TIME_STEP);
            } else {
              frameSteps = getFrameSteps(nextTime, frameRunner.interpolatedValues[$scope.selectedObject.name]);
              console.log("scope_time", scope_time);
              _results = [];
              while (nextTime !== scope_time) {
                nextTime -= TIME_STEP;
                frameRunner = $scope.frames[nextTime];
                prevFrameRunner = $scope.frames[nextTime + TIME_STEP];
                _results.push((function() {
                  var _j, _len1, _ref1, _results1;
                  _ref1 = $scope.keyframedProperties;
                  _results1 = [];
                  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                    property = _ref1[_j];
                    name = $scope.selectedObject.name;
                    rv = parseFloat(prevFrameRunner.interpolatedValues[name][property]) + parseFloat(frameSteps[property]);
                    _results1.push($scope.setPropertyAtFrame(property, nextTime, rv.toFixed(3)));
                  }
                  return _results1;
                })());
              }
              return _results;
            }
          };
          if ($scope.time > $scope.timeStart) {
            runInterpolationWalk($scope.time, false);
            console.log($scope.frames);
          }
          if ($scope.selectedObject.furthestFrameTime < $scope.time) {
            return $scope.selectedObject.furthestFrameTime = $scope.time;
          } else {
            runInterpolationWalk($scope.time, true);
            return console.log($scope.frames);
          }
        };
      };
      return window.JuicerController.$inject = ['$scope', '$timeout'];
    };
    return {
      init: function() {
        initAppModule();
        return angular.bootstrap(document, ['juicer']);
      }
    };
  });

}).call(this);
