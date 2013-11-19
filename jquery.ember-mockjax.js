var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($) {
  return $.emberMockJax = function(options) {
    var config, findRecords, log, parseUrl, settings;
    config = {
      fixtures: {},
      urls: ["*"],
      debug: false
    };
    settings = $.extend(settings, options);
    log = function(msg) {
      if (settings.debug) {
        return typeof console !== "undefined" && console !== null ? console.log(msg) : void 0;
      }
    };
    parseUrl = function(url) {
      var parser;
      parser = document.createElement('a');
      parser.href = url;
      return parser;
    };
    findRecords = function(fixtures, fixtureName, queryParams, requestData) {
      if (settings.debug) {
        console.log("=== findRecords =====================");
        console.log("fixtures", fixtures);
        console.log("fixtureName", fixtureName);
        console.log("queryParams", queryParams);
        console.log("requestData", requestData);
        console.log("=====================================");
        console.log("-");
      }
      return fixtures[fixtureName].filter(function(element, index) {
        var matches, param, _i, _len, _ref;
        matches = 0;
        for (_i = 0, _len = queryParams.length; _i < _len; _i++) {
          param = queryParams[_i];
          if (!requestData[param]) {
            continue;
          }
          if (settings.debug) {
            console.log("=== queryParams =====================");
            console.log("queryParams", queryParams);
            console.log("element", element);
            console.log("param", param);
            console.log("requestData", requestData);
            console.log("queryParams", queryParams);
            console.log("queryParams[param]", queryParams[param]);
            console.log("=== queryParams =====================");
            console.log("-");
          }
          if (typeof requestData[param] === "object") {
            if (_ref = element[param.singularize()].toString(), __indexOf.call(requestData[param], _ref) >= 0) {
              matches += 1;
            }
          } else {
            if (requestData[param] = element[param]) {
              matches += 1;
            }
          }
        }
        if (matches === queryParams.length) {
          return true;
        }
      });
    };
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var emberRelationshipNames, emberRelationships, fixtureName, fixtures, json, modelAttributes, modelName, pathObject, queryParams, requestType, resourceName, urlObject, urls;
        queryParams = [];
        requestType = request.type.toLowerCase();
        urlObject = parseUrl(request.url);
        pathObject = urlObject["pathname"].split("/");
        modelName = pathObject.slice(-1).pop();
        if (/^[0-9]+$/.test(modelName)) {
          modelName = pathObject.slice(-2).shift().singularize().camelize().capitalize();
        } else {
          modelName = modelName.singularize().camelize().capitalize();
        }
        fixtureName = modelName.pluralize();
        resourceName = modelName.underscore().pluralize();
        emberRelationships = Ember.get(App[modelName], "relationshipsByName");
        emberRelationshipNames = emberRelationships.keys.list;
        fixtures = settings.fixtures;
        urls = settings.urls;
        if (typeof request.data === "object") {
          queryParams = Object.keys(request.data);
        }
        modelAttributes = Object.keys(App[modelName].prototype).filter(function(e) {
          if (!(e === "constructor" || __indexOf.call(emberRelationshipNames, e) >= 0)) {
            return true;
          }
        });
        settings.debug = false;
        if (settings.debug) {
          console.log("=== MockJax request ========================");
          console.log("request", request);
          console.log("modelName", modelName);
          console.log("========================================");
          console.log("-");
        }
        settings.debug = false;
        json = {};
        if (requestType === "get") {
          if (!fixtures[fixtureName]) {
            console.warn("Fixtures not found for Model : " + modelName);
          }
          if (queryParams.length) {
            json[resourceName] = findRecords(fixtures, fixtureName, queryParams, request.data);
          } else {
            json[resourceName] = fixtures[fixtureName];
          }
        }
        this.responseText = json;
        return console.log("MOCKJAX RESPONSE:", json);
      }
    });
  };
})(jQuery);

/*
//@ sourceMappingURL=jquery.ember-mockjax.js.map
*/