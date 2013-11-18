var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($) {
  return $.emberMockJax = function(options) {
    var config, log, parseUrl, settings;
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
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var emberRelationshipNames, emberRelationships, fixtureName, fixtures, json, modelAttributes, modelName, pathObject, queryParams, requestType, resourceName, urlObject, urls;
        console.log("DEBUG==========================");
        console.log("request", request);
        requestType = request.type.toLowerCase();
        urlObject = parseUrl(request.url);
        pathObject = urlObject["pathname"].split("/");
        modelName = pathObject.slice(-1).pop().singularize().camelize().capitalize();
        fixtureName = modelName.pluralize();
        resourceName = modelName.underscore().pluralize();
        emberRelationships = Ember.get(App[modelName], "relationshipsByName");
        emberRelationshipNames = emberRelationships.keys.list;
        fixtures = settings.fixtures;
        urls = settings.urls;
        queryParams = Object.keys(request.data);
        modelAttributes = Object.keys(App[modelName].prototype).filter(function(e) {
          if (!(e === "constructor" || __indexOf.call(emberRelationshipNames, e) >= 0)) {
            return true;
          }
        });
        json = {};
        if (requestType === "get") {
          if (!fixtures[fixtureName]) {
            console.warn("Fixtures not found for Model : " + modelName);
          }
          if (queryParams.length) {
            json[resourceName] = fixtures[fixtureName].filter(function(element, index) {
              var matches, param, _i, _len;
              matches = 0;
              for (_i = 0, _len = queryParams.length; _i < _len; _i++) {
                param = queryParams[_i];
                if (request.data[param] = element[param]) {
                  matches += 1;
                }
              }
              if (matches === queryParams.length) {
                return true;
              }
            });
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