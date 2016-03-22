'frontendApp.services.Prompt',

  /*jshint unused: vars */
  define(['angular', 'controllers/main', 'controllers/about', 'services/prompt']/*deps*/, function (angular, MainCtrl, AboutCtrl, PromptFactory)/*invoke*/ {
    'use strict';

    /**
     * @ngdoc overview
     * @name frontendApp
     * @description
     * # frontendApp
     *
     * Main module of the application.
     */
    return angular.module('frontendApp', ['frontendApp.controllers.MainCtrl', 'frontendApp.controllers.AboutCtrl', 'frontendApp.services.Prompt',
        'ngCookies', 'ngMessages', 'ngResource', 'ngSanitize', 'ngRoute', 'ngAnimate', 'ngTouch',])
      .config(function ($routeProvider) {
        $routeProvider
          .when('/', {
            templateUrl: 'views/main.html',
            controller: 'MainCtrl',
            controllerAs: 'main'
          })
          .when('/about', {
            templateUrl: 'views/about.html',
            controller: 'AboutCtrl',
            controllerAs: 'about'
          })
          .otherwise({
            redirectTo: '/'
          });
      });
  });
