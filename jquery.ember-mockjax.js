(function($) {
  return $.emberMockJax = function(options) {
    var config, error, findRecords, getModelName, getQueryParams, getRelationships, getRequestType, log, responseJSON, settings;
    responseJSON = {};
    config = {
      fixtures: {},
      urls: ["*"],
      debug: true
    };
    settings = $.extend(config, options);
    log = function(msg, obj) {
      if (!obj) {
        obj = msg;
        msg = "no message";
      }
      if (settings.debug) {
        return typeof console !== "undefined" && console !== null ? console.log(msg, obj) : void 0;
      }
    };
    error = function(msg) {
      return typeof console !== "undefined" && console !== null ? console.error("jQuery-Ember-MockJax ERROR: " + msg) : void 0;
    };
    getRequestType = function(request) {
      return request.type.toLowerCase();
    };
    getModelName = function(request) {
      return request.url.replace("/" + config.namespace).split("/")[1];
    };
    getQueryParams = function(request) {
      if (typeof request.data === "object") {
        return Object.keys(request.data);
      }
    };
    getRelationships = function(modelName) {
      return Em.get(App[modelName], "relationshipsByName");
    };
    String.prototype.fixtureize = function() {
      if (typeof name === "string") {
        return this.camelize().capitalize().pluralize();
      }
    };
    String.prototype.resourceize = function() {
      if (typeof name === "string") {
        return this.pluralize().underscore();
      }
    };
    String.prototype.modelize = function() {
      if (typeof name === "string") {
        return this.singularize().camelize().capitalize();
      }
    };
    findRecords = function(modelName, params) {
      var fixtureName;
      fixtureName = modelName.fixtureize();
      return config.fixtures[fixtureName].filter(function(record) {
        var param;
        for (param in params) {
          if (record[param] !== params[param] && (record[param] != null)) {
            return false;
          }
        }
        return true;
      });
    };
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var queryParams, requestType, rootModelName;
        requestType = getRequestType(request);
        rootModelName = getModelName(request);
        queryParams = getQueryParams(request);
        if (requestType === "get") {
          if (!config.fixtures[rootModelName.fixtureize()]) {
            error("Fixtures not found for Model : " + (rootModelName.fixturize()));
          }
          responseJSON[rootModelName] = findRecords(rootModelName, queryParams);
          return this.responseText = responseJSON;
        }
      }
    });
  };
})(jQuery);

/*
//@ sourceMappingURL=jquery.ember-mockjax.js.map
*/