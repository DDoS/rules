/*jshint unused: vars */
define(['angular', 'angular-mocks', 'app'], function(angular, mocks, app) {
  'use strict';

  describe('Service: dragging', function () {

    // load the service's module
    beforeEach(module('frontendApp.services.Dragging'));

    // instantiate service
    var dragging;
    beforeEach(inject(function (_dragging_) {
      dragging = _dragging_;
    }));

    it('should do something', function () {
      expect(!!dragging).toBe(true);
    });

  });
});
