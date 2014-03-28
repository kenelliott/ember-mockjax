(function($) {
  return $.emberMockJax = function(options) {
    var config, findRecords, getModelName, getRequestType, log, settings;
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
    getRequestType = function(request) {
      return request.type.toLowerCase();
    };
    getModelName = function(request) {
      return request.url.replace("/" + config.namespace).split("/")[1];
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
    findRecords = function(modelName) {
      var fixtureName;
      fixtureName = modelName.fixtureize();
      return log("fixtureName", fixtureName);
    };
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var requestType, rootModelName;
        log("request", request);
        requestType = getRequestType(request);
        rootModelName = getModelName(request);
        if (requestType === "get") {
          if (!config.fixtures[rootModelName.fixtureize()]) {
            console.warn("Fixtures not found for Model : " + rootModelName);
          }
          return log("rootModelName", rootModelName);
        }
      }
    });
  };
})(jQuery);

/*
//@ sourceMappingURL=jquery.ember-mockjax.js.map
*/