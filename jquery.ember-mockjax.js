var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($) {
  return $.emberMockJax = function(options) {
    var config, findRecords, log, parseUrl, settings, sideloadRecords, uniqueArray;
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
      return fixtures[fixtureName].filter(function(element, index) {
        var matches, param, _i, _len, _ref, _ref1;
        matches = 0;
        for (_i = 0, _len = queryParams.length; _i < _len; _i++) {
          param = queryParams[_i];
          if (!requestData[param]) {
            continue;
          }
          if (typeof requestData[param] === "object") {
            if ((_ref = element[param.singularize()].toString(), __indexOf.call(requestData[param], _ref) >= 0) || (_ref1 = element[param.singularize()], __indexOf.call(requestData[param], _ref1) >= 0)) {
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
    uniqueArray = function(arr) {
      arr = arr.map(function(k) {
        return k.toString();
      });
      return $.grep(arr, function(v, k) {
        return $.inArray(v, arr) === k;
      });
    };
    sideloadRecords = function(fixtures, name, parent) {
      var params, res, temp;
      temp = [];
      params = [];
      res = [];
      parent.forEach(function(record) {
        return $.merge(res, record[name.singularize() + "_ids"]);
      });
      params["ids"] = uniqueArray(res);
      return findRecords(fixtures, name.capitalize(), ["ids"], params);
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
          console.log("emberRelationships", emberRelationships);
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
          emberRelationships.forEach(function(name, relationship) {
            if (__indexOf.call(Object.keys(relationship.options), "async") >= 0) {
              if (!relationship.options.async) {
                return json[name] = sideloadRecords(fixtures, name, json[resourceName]);
              }
            }
          });
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