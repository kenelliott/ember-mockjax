(function($) {
  return $.emberMockJax = function(options) {
    var addError, addFixtureRecord, addRelatedFixtureRecords, buildResponseJSON, checkValidations, config, error, findRecords, getFactory, getFixtureById, getModelName, getNextFixtureID, getQueryParams, getRelationshipIds, getRelationships, getRequestType, getSideloadedRecords, log, normalizeRequest, removeIgnoredAttributes, responseJSON, setDefaultValues, setRecordDefaults, splitUrl, uniqueArray, validate;
    responseJSON = {};
    config = {
      fixtures: {},
      factories: {},
      urls: ["*"],
      debug: false,
      namespace: "",
      scopePrefixes: ["by_", "has_"],
      nestedSuffix: "attributes",
      deleteAttribute: "_delete"
    };
    $.extend(config, options);
    $.mockjaxSettings.logging = config.debug;
    log = function(msg, obj) {
      if (!obj) {
        obj = msg;
        return msg = "no message";
      }
    };
    error = function(msg) {
      return typeof console !== "undefined" && console !== null ? console.error("jQuery-Ember-MockJax ERROR: " + msg) : void 0;
    };
    uniqueArray = function(arr) {
      arr = arr.map(function(k) {
        if (k !== null) {
          return k.toString();
        }
      });
      return $.grep(arr, function(v, k) {
        return $.inArray(v, arr) === k;
      });
    };
    getRequestType = function(request) {
      return request.type.toLowerCase();
    };
    splitUrl = function(url) {
      return url.replace("/" + config.namespace, "").split("/");
    };
    getModelName = function(request) {
      return splitUrl(request.url).shift();
    };
    getQueryParams = function(request) {
      var id, modelName;
      id = splitUrl(request.url)[1];
      if (getRequestType(request) === "put") {
        request.data = JSON.parse(request.data);
        modelName = getModelName(request).attributize();
        if (id) {
          request.data[modelName].id = parseInt(id);
        }
        request.data = JSON.stringify(request.data);
      } else {
        if (!request.data) {
          request.data = [];
        }
        if (id) {
          request.data.id = parseInt(id);
        }
      }
      return request.data;
    };
    getRelationships = function(modelName) {
      var map;
      map = Ember.Map.create();
      App[modelName.modelize()].eachComputedProperty(function(name, meta) {
        if (meta.isRelationship) {
          return map.set(name, meta);
        }
      });
      return map;
    };
    String.prototype.fixtureize = function() {
      return this.pluralize().camelize().capitalize();
    };
    String.prototype.resourceize = function() {
      return this.pluralize().underscore();
    };
    String.prototype.modelize = function() {
      return this.singularize().camelize().capitalize();
    };
    String.prototype.attributize = function() {
      return this.singularize().underscore();
    };
    findRecords = function(modelName, params) {
      var fixtureName;
      fixtureName = modelName.fixtureize();
      if (!config.fixtures[fixtureName]) {
        error("Fixtures not found for Model : " + fixtureName);
      }
      return config.fixtures[fixtureName].filter(function(record) {
        var param, _i, _len, _ref;
        _ref = Object.keys(params);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          param = _ref[_i];
          if (!params.hasOwnProperty(param)) {
            continue;
          }
          if (record[param] !== params[param] && (record[param] != null)) {
            return false;
          } else if (param === "ids" && params[param].indexOf(record.id.toString()) < 0) {
            return false;
          }
        }
        return true;
      });
    };
    buildResponseJSON = function(modelName, queryParams) {
      responseJSON[modelName] = findRecords(modelName, queryParams);
      return getSideloadedRecords(modelName);
    };
    getRelationshipIds = function(modelName, relatedModel, relationshipType) {
      var ids;
      ids = [];
      responseJSON[modelName].forEach(function(record) {
        if (relationshipType === "belongsTo") {
          return ids.push(record["" + (relatedModel.attributize()) + "_id"]);
        } else {
          return $.merge(ids, record["" + (relatedModel.attributize()) + "_ids"]);
        }
      });
      return uniqueArray(ids);
    };
    normalizeRequest = function(request) {
      var params;
      params = $.parseParams(request.url);
      request.url = request.url.split("?")[0];
      request.data = request.data ? $.merge(request.data, params) : params;
      return request;
    };
    getSideloadedRecords = function(modelName) {
      var relationships;
      relationships = getRelationships(modelName);
      return relationships.forEach(function(relatedModel, relationship) {
        var params;
        if ((relationship.options.async == null) || relationship.options.async === true) {
          return;
        }
        params = [];
        params["ids"] = getRelationshipIds(modelName, relatedModel, relationship.kind);
        responseJSON[relatedModel.resourceize()] = findRecords(relatedModel, params);
        return getSideloadedRecords(relatedModel);
      });
    };
    getNextFixtureID = function(modelName) {
      return config.fixtures[modelName.fixtureize()].slice(0).sort(function(a, b) {
        return b.id - a.id;
      })[0].id + 1;
    };
    setDefaultValues = function(request, modelName) {
      var record;
      record = JSON.parse(request.data)[modelName.attributize()];
      return setRecordDefaults(record, modelName);
    };
    setRecordDefaults = function(record, modelName) {
      var factory;
      modelName.modelize();
      factory = getFactory(modelName);
      Object.keys(record).forEach(function(key) {
        var def, prop, _ref;
        prop = record[key];
        def = (_ref = factory[key.camelize()]) != null ? _ref["default"] : void 0;
        if (typeof prop === "object" && prop === null && def) {
          return record[key] = def;
        } else if (typeof prop === "object" && prop !== null) {
          return record[key] = setRecordDefaults(record[key], key.replace("_attributes", ""));
        }
      });
      return record;
    };
    getFactory = function(modelName) {
      return config.factories[modelName.fixtureize()];
    };
    removeIgnoredAttributes = function(modelName, record) {
      var factory, relationships;
      factory = getFactory(modelName);
      Object.keys(factory).forEach(function(attr) {
        if (factory[attr].ignore) {
          return delete record[attr.attributize()];
        }
      });
      relationships = getRelationships(modelName);
      return relationships.forEach(function(relatedModelName, relationship) {
        var attributeName;
        attributeName = relationship.kind === "hasMany" ? relatedModelName.resourceize() : relatedModelName.attributize();
        attributeName += "_attributes";
        if (record[attributeName] != null) {
          return removeIgnoredAttributes(relatedModelName, record[attributeName]);
        }
      });
    };
    addError = function(errorObj, errorKey, error) {
      if (!errorObj.errors[errorKey]) {
        errorObj.errors[errorKey] = [];
      }
      return errorObj.errors[errorKey].push(error);
    };
    checkValidations = function(errorObj, factory, key, value, prepend) {
      var errorKey, validations;
      validations = factory[key].validation;
      if (!validations) {
        return;
      }
      errorKey = prepend ? "" + prepend + "." + key : key;
      if (validations.required && !value) {
        addError(errorObj, errorKey, "is required");
      }
      if (validations.matches && !validations.matches.test(value)) {
        return addError(errorObj, errorKey, "is invalid");
      }
    };
    validate = function(errorObj, modelName, record, prepend) {
      var attributes, factory, key, prependName, relationships, value;
      modelName = modelName.modelize();
      attributes = Em.get(App[modelName], "attributes");
      relationships = getRelationships(modelName);
      factory = getFactory(modelName.resourceize());
      if (!factory) {
        return;
      }
      for (key in record) {
        value = record[key];
        key = key.replace("_attributes", "");
        if ((value != null) && typeof value === "object" && relationships.has(key)) {
          prependName = prepend ? "" + prepend + "." + key : key;
          validate(errorObj, key, value, prependName);
        } else if (attributes.has(key)) {
          checkValidations(errorObj, factory, key, value, prepend);
        }
      }
      if (!(Object.keys(errorObj.errors).length > 0)) {
        return true;
      }
    };
    addRelatedFixtureRecords = function(modelName, record, requestType) {
      var relationships;
      removeIgnoredAttributes(modelName, record);
      relationships = getRelationships(modelName);
      if (requestType !== "put") {
        record.id = getNextFixtureID(modelName);
      }
      relationships.forEach(function(relatedModelName, relationship) {
        var attributeName, fixture;
        attributeName = relationship.kind === "hasMany" ? relatedModelName.resourceize() : relatedModelName.attributize();
        attributeName += "_attributes";
        if (relationship.options.nested && (record[attributeName] != null)) {
          if (relationship.kind === "hasMany") {
            record["" + relatedModelName + "_ids"] = [];
            record[attributeName].forEach(function(relatedRecord) {
              if (!relatedRecord.id) {
                relatedRecord.id = getNextFixtureID(modelName);
                return record["" + relatedModelName + "_ids"].push(addFixtureRecord(relatedModelName, relatedRecord));
              } else {
                relatedRecord.id = parseInt(relatedRecord.id);
                return $.extend(getFixtureById(relatedModelName, record[attributeName].id), relatedRecord);
              }
            });
          } else {
            if (!record[attributeName].id) {
              record[attributeName].id = getNextFixtureID(relatedModelName);
              record["" + relatedModelName + "_id"] = addFixtureRecord(relatedModelName, record[attributeName]);
            } else {
              record["" + relatedModelName + "_id"] = record[attributeName].id;
              fixture = getFixtureById(relatedModelName, record[attributeName].id);
              record[attributeName].id = parseInt(record[attributeName].id);
              $.extend(fixture, record[attributeName]);
            }
          }
          return delete record[attributeName];
        }
      });
      return record;
    };
    addFixtureRecord = function(modelName, record) {
      config.fixtures[modelName.fixtureize()].push(record);
      return record.id;
    };
    getFixtureById = function(fixtureName, id) {
      return config.fixtures[fixtureName.fixtureize()].filterBy("id", parseInt(id)).get("firstObject");
    };
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var errorObj, id, newRecord, queryParams, requestType, rootModelName, updateFixture, updateRecord;
        responseJSON = {};
        request = normalizeRequest(request);
        requestType = getRequestType(request);
        rootModelName = getModelName(request);
        errorObj = {
          errors: {}
        };
        if (requestType === "post") {
          newRecord = setDefaultValues(request, rootModelName);
          if (!validate(errorObj, rootModelName, newRecord)) {
            this.responseText = errorObj;
            this.status = 422;
            return;
          }
          addRelatedFixtureRecords(rootModelName, newRecord);
          id = addFixtureRecord(rootModelName, newRecord);
          queryParams = [];
          queryParams.id = id;
          buildResponseJSON(rootModelName, queryParams);
        } else if (requestType === "put") {
          queryParams = getQueryParams(request);
          updateRecord = JSON.parse(queryParams)[rootModelName.attributize()];
          if (!validate(errorObj, rootModelName, updateRecord)) {
            this.responseText = errorObj;
            this.status = 422;
            return;
          }
          updateFixture = getFixtureById(rootModelName, updateRecord.id);
          updateRecord = addRelatedFixtureRecords(rootModelName, updateRecord, requestType);
          queryParams = [];
          $.extend(getFixtureById(rootModelName, updateRecord.id), updateRecord);
          queryParams.id = updateRecord.id;
          buildResponseJSON(rootModelName, queryParams);
        } else if (requestType === "get") {
          queryParams = getQueryParams(request);
          buildResponseJSON(rootModelName, queryParams);
        }
        this.responseText = responseJSON;
        if ($.mockjaxSettings.logging) {
          return console.log("MOCK RSP:", request.url, this.responseText);
        }
      }
    });
  };
})(jQuery);

(function($) {
  var decode, re;
  re = /([^&=]+)=?([^&]*)/g;
  decode = function(str) {
    return decodeURIComponent(str.replace(/\+/g, " "));
  };
  $.parseParams = function(query) {
    var createElement, e, key, params, value;
    createElement = function(params, key, value) {
      var index, list, new_key;
      key = key + "";
      if (key.indexOf(".") !== -1) {
        list = key.split(".");
        new_key = key.split(/\.(.+)?/)[1];
        if (!params[list[0]]) {
          params[list[0]] = {};
        }
        if (new_key !== "") {
          createElement(params[list[0]], new_key, value);
        } else {
          console.warn("parseParams :: empty property in key \"" + key + "\"");
        }
      } else if (key.indexOf("[") !== -1) {
        list = key.split("[");
        key = list[0];
        list = list[1].split("]");
        index = list[0];
        if (index === "") {
          if (!params) {
            params = {};
          }
          if (!params[key] || !$.isArray(params[key])) {
            params[key] = [];
          }
          params[key].push(value);
        } else {
          if (!params) {
            params = {};
          }
          if (!params[key] || !$.isArray(params[key])) {
            params[key] = [];
          }
          params[key][parseInt(index)] = value;
        }
      } else {
        if (!params) {
          params = {};
        }
        params[key] = value;
      }
    };
    query = query + "";
    if (query === "") {
      query = window.location + "";
    }
    params = {};
    e = void 0;
    if (query) {
      if (query.indexOf("#") !== -1) {
        query = query.substr(0, query.indexOf("#"));
      }
      if (query.indexOf("?") !== -1) {
        query = query.substr(query.indexOf("?") + 1, query.length);
      } else {
        return {};
      }
      if (query === "") {
        return {};
      }
      while (e = re.exec(query)) {
        key = decode(e[1]);
        value = decode(e[2]);
        createElement(params, key, value);
      }
    }
    return params;
  };
})(jQuery);

//# sourceMappingURL=jquery.ember-mockjax.js.map
