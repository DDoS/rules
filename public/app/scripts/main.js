/*jshint unused: vars */
require.config({
  paths: {
    angular: '../../bower_components/angular/angular',
    'angular-animate': '../../bower_components/angular-animate/angular-animate',
    'angular-cookies': '../../bower_components/angular-cookies/angular-cookies',
    'angular-messages': '../../bower_components/angular-messages/angular-messages',
    'angular-mocks': '../../bower_components/angular-mocks/angular-mocks',
    'angular-resource': '../../bower_components/angular-resource/angular-resource',
    'angular-route': '../../bower_components/angular-route/angular-route',
    'angular-sanitize': '../../bower_components/angular-sanitize/angular-sanitize',
    'angular-touch': '../../bower_components/angular-touch/angular-touch',
    'angular-flowchart': '../../bower_components/AngularJS-FlowChart/flowchart/flowchart',
    jquery: '../../bower_components/jquery/dist/jquery.min',
    jsPlumbToolkit: '../lib/jsPlumbToolkit-1.0.20',
    jsPlumb: '../lib/jsPlumb-2.0.7',
    'jquery-validate': '../lib/jquery.validate',
    additional: '../lib/additional-methods',
    braintree: '../lib/braintree',
    bootstrap: '../../bower_components/bootstrap/dist/js/bootstrap'
  },
  shim: {
    angular: {
      exports: 'angular'
    },
    'angular-route': [
      'angular'
    ],
    'angular-cookies': [
      'angular'
    ],
    'angular-messages': [
      'angular'
    ],
    'angular-sanitize': [
      'angular'
    ],
    'angular-resource': [
      'angular'
    ],
    'angular-animate': [
      'angular'
    ],
    'angular-touch': [
      'angular'
    ],
    'angular-flowchart': [
      'angular'
    ],
    jsPlumb: [
      'angular'
    ],
    jsPlumbToolkit: [
      'jsPlumb'
    ],
    'jquery-validate': [
      'jquery'
    ],
    additional: [
      'jquery-validate'
    ],
    braintree: [
      'additional'
    ],
    'angular-mocks': {
      deps: [
        'angular'
      ],
      exports: 'angular.mock'
    }
  },
  priority: [
    'angular'
  ],
  packages: [

  ]
});

//http://code.angularjs.org/1.2.1/docs/guide/bootstrap#overview_deferred-bootstrap
window.name = 'NG_DEFER_BOOTSTRAP!';

require([
  'angular',
  'app',
  'angular-route',
  'angular-cookies',
  'angular-messages',
  'angular-sanitize',
  'angular-resource',
  'angular-animate',
  'angular-touch',
  'angular-flowchart',
  'jsPlumbToolkit',
  'jsPlumb'
], function (angular, app, ngRoutes, ngCookies, ngSanitize, ngResource, ngAnimate, ngTouch, flowChart) {
  'use strict';
  /* jshint ignore:start */
  var $html = angular.element(document.getElementsByTagName('html')[0]);
  /* jshint ignore:end */
  angular.element().ready(function () {
    angular.resumeBootstrap([app.name]);
  });
});
