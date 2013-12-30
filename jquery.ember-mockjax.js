var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($) {
  return $.emberMockJax = function(options) {
    var addRecord, addRelatedRecord, allPropsNull, buildErrorObject, config, findRecords, flattenObject, log, parseUrl, setErrorMessages, settings, sideloadRecords, uniqueArray;
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
        var bool, matches, param, _i, _len, _ref, _ref1;
        matches = 0;
        for (_i = 0, _len = queryParams.length; _i < _len; _i++) {
          param = queryParams[_i];
          if (requestData[param] == null) {
            continue;
          }
          if (typeof requestData[param] === "object") {
            if ((_ref = element[param.singularize()].toString(), __indexOf.call(requestData[param], _ref) >= 0) || (_ref1 = element[param.singularize()], __indexOf.call(requestData[param], _ref1) >= 0)) {
              matches += 1;
            }
          } else if (typeof requestData[param] === "boolean") {
            if ((element[param] != null) === true) {
              bool = true;
            } else {
              bool = false;
            }
            if (requestData[param] === bool) {
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
        return $.merge(res, record[name.underscore().singularize() + "_ids"]);
      });
      params["ids"] = uniqueArray(res);
      return findRecords(fixtures, name.capitalize(), ["ids"], params);
    };
    addRelatedRecord = function(fixtures, json, name, new_record, singleResourceName) {
      var duplicated_record;
      if (typeof json[name.resourceize()] !== "object") {
        json[name.resourceize()] = [];
      }
      duplicated_record = $.extend(true, {}, fixtures[name.fixtureize()].slice(-1).pop());
      duplicated_record.id = parseInt(duplicated_record.id) + 1;
      $.extend(duplicated_record, new_record[singleResourceName][name + "_attributes"]);
      fixtures[name.fixtureize()].push(duplicated_record);
      delete new_record[singleResourceName][name + "_attributes"];
      new_record[singleResourceName][name + "_id"] = duplicated_record.id;
      json[name.resourceize()].push(duplicated_record);
      return json;
    };
    addRecord = function(fixtures, json, new_record, fixtureName, resourceName, singleResourceName) {
      var duplicated_record;
      duplicated_record = $.extend(true, {}, fixtures[fixtureName].slice(-1).pop());
      duplicated_record.id = parseInt(duplicated_record.id) + 1;
      duplicated_record.archived_at = null;
      $.extend(duplicated_record, new_record[singleResourceName]);
      fixtures[fixtureName].push(duplicated_record);
      json[resourceName].push(duplicated_record);
      return json;
    };
    allPropsNull = function(obj, msg) {
      return Object.keys(obj).every(function(key) {
        if (obj[key] !== null) {
          if (typeof obj[key] === "object") {
            return allPropsNull(obj[key]);
          }
        } else {
          return true;
        }
      });
    };
    flattenObject = function(obj, result) {
      var keys;
      if (!result) {
        result = {};
      }
      keys = Object.keys(obj);
      keys.forEach(function(key) {
        if (obj[key] === null) {
          return delete obj[key];
        } else if (typeof obj[key] === "object") {
          return result = flattenObject(obj[key], result);
        } else {
          return result[key] = [obj[key]];
        }
      });
      return result;
    };
    setErrorMessages = function(obj, msg, parentKeys) {
      var path;
      if (!parentKeys) {
        parentKeys = [];
        path = "";
      }
      Object.keys(obj).every(function(key) {
        if (obj[key] !== null) {
          if (typeof obj[key] === "object") {
            parentKeys.push(key.replace("_attributes", ""));
            return obj[key] = setErrorMessages(obj[key], msg, parentKeys);
          }
        } else {
          if (parentKeys.length) {
            path = parentKeys.join(".") + ".";
          }
          return obj["" + path + key] = "" + msg;
        }
      });
      return obj;
    };
    buildErrorObject = function(obj, msg) {
      var rootKey;
      rootKey = Object.keys(obj).pop();
      obj["errors"] = flattenObject(setErrorMessages(obj[rootKey], msg));
      delete obj[rootKey];
      return obj;
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
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var emberRelationships, fixtureName, fixtures, json, modelAttributes, modelName, new_record, pathObject, putId, queryParams, requestType, resourceName, singleResourceName;
        queryParams = [];
        json = {};
        requestType = request.type.toLowerCase();
        pathObject = parseUrl(request.url)["pathname"].split("/");
        modelName = pathObject.slice(-1).pop();
        putId = null;
        if (/^[0-9]+$/.test(modelName)) {
          if (requestType === "get") {
            if (typeof request.data === "undefined") {
              request.data = {};
            }
            request.data.ids = [modelName];
          }
          if (requestType === "put") {
            putId = modelName;
          }
          modelName = pathObject.slice(-2).shift().singularize().camelize().capitalize();
        } else {
          modelName = modelName.singularize().camelize().capitalize();
        }
        fixtureName = modelName.fixtureize();
        resourceName = modelName.resourceize();
        singleResourceName = resourceName.singularize();
        emberRelationships = Ember.get(App[modelName], "relationshipsByName");
        fixtures = settings.fixtures;
        if (typeof request.data === "object") {
          queryParams = Object.keys(request.data);
        }
        modelAttributes = Object.keys(App[modelName].prototype).filter(function(e) {
          if (!(e === "constructor" || __indexOf.call(emberRelationships.keys.list, e) >= 0)) {
            return true;
          }
        });
        if (requestType === "post") {
          new_record = JSON.parse(request.data);
          if (allPropsNull(new_record)) {
            this.status = 422;
            this.responseText = buildErrorObject(new_record, "cannot be empty.");
          } else {
            json[resourceName] = [];
            emberRelationships.forEach(function(name, relationship) {
              if (__indexOf.call(Object.keys(relationship.options), "nested") >= 0) {
                if (!relationship.options.async) {
                  return json = addRelatedRecord(fixtures, json, name, new_record, singleResourceName);
                }
              }
            });
            this.responseText = addRecord(fixtures, json, new_record, fixtureName, resourceName, singleResourceName);
          }
        }
        if (requestType === "put") {
          new_record = JSON.parse(request.data);
          json[resourceName] = [];
          emberRelationships.forEach(function(name, relationship) {
            if (__indexOf.call(Object.keys(relationship.options), "nested") >= 0) {
              if (!relationship.options.async) {
                fixtures[name.fixtureize()].forEach(function(record) {
                  if (record.id === parseInt(new_record[singleResourceName][name.underscore() + "_attributes"].id)) {
                    $.extend(record, new_record[singleResourceName][name.underscore() + "_attributes"]);
                    if (typeof json[name.resourceize()] === "undefined") {
                      json[name.resourceize()] = [];
                    }
                    return json[name.resourceize()].push(record);
                  }
                });
                return delete new_record[singleResourceName][name.underscore() + "_attributes"];
              }
            }
          });
          fixtures[fixtureName].forEach(function(record) {
            if (record.id === parseInt(putId)) {
              if (typeof json[resourceName] === "undefined") {
                json[resourceName] = [];
              }
              $.extend(record, new_record[singleResourceName]);
              return json[resourceName].push(record);
            }
          });
          this.responseText = json;
        }
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
          this.responseText = json;
        }
        if ($.mockjaxSettings.logging) {
          return console.log("MOCK RSP:", request.url, this.responseText);
        }
      }
    });
  };
})(jQuery);

/*
//@ sourceMappingURL=jquery.ember-mockjax.js.map
*/