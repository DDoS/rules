/*jshint unused: vars */
define(['angular', 'angular-mocks', 'app'], function(angular, mocks, app) {
  'use strict';

  describe('Service: mouseCapture', function () {

    // load the service's module
    beforeEach(module('frontendApp.services.MouseCapture'));

    // instantiate service
    var mouseCapture;
    beforeEach(inject(function (_mouseCapture_) {
      mouseCapture = _mouseCapture_;
    }));

    it('should do something', function () {
      expect(!!mouseCapture).toBe(true);
    });

  });
});
