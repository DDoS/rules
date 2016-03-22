define(['angular'], function (angular) {
  'use strict';

  /**
   * @ngdoc service
   * @name frontendApp.prompt
   * @description
   * # prompt
   * Factory in the frontendApp.
   */
  angular.module('frontendApp.services.Prompt', [])
    .factory('prompt', function () {
      /* Uncomment the following to test that the prompt service is working as expected.
       return function () {
       return "Test!";
       }
       */

      // Return the browsers prompt function.
      return prompt;
    });
})
;
