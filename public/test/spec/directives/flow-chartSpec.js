/*jshint unused: vars */
define(['angular', 'angular-mocks', 'app'], function(angular, mocks, app) {
  'use strict';

  describe('Directive: flowChart', function () {

    // load the directive's module
    beforeEach(module('frontendApp.directives.FlowChart'));

    var element,
      scope;

    beforeEach(inject(function ($rootScope) {
      scope = $rootScope.$new();
    }));

    it('should make hidden element visible', inject(function ($compile) {
      element = angular.element('<flow-chart></flow-chart>');
      element = $compile(element)(scope);
      expect(element.text()).toBe('this is the flowChart directive');
    }));
  });
});
