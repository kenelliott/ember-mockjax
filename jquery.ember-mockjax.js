(function($) {
  return $.emberMockJax = function(options) {
    var buildResponseJSON, config, error, findRecords, getFactory, getModelName, getNextFixtureID, getQueryParams, getRelatedModels, getRelationshipIds, getRelationships, getRequestType, log, responseJSON, setDefaultValues, setRecordDefaults, uniqueArray;
    responseJSON = {};
    config = {
      fixtures: {},
      factories: {},
      urls: ["*"],
      debug: false,
      namespace: ""
    };
    $.extend(config, options);
    console.log("config", config);
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
    getModelName = function(request) {
      return request.url.replace("/" + config.namespace, "").split("/").shift();
    };
    getQueryParams = function(request) {
      if (typeof request.data === "object") {
        return Object.keys(request.data);
      }
    };
    getRelationships = function(modelName) {
      return Em.get(App[modelName.modelize()], "relationshipsByName");
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
        var param;
        for (param in params) {
          if (record[param] !== params[param] && (record[param] != null)) {
            return false;
          }
        }
        return true;
      });
    };
    buildResponseJSON = function(modelName, queryParams) {
      responseJSON[modelName] = findRecords(modelName, queryParams);
      return getRelatedModels(modelName);
    };
    getRelationshipIds = function(modelName, relatedModel, relationshipType) {
      var ids;
      ids = [];
      responseJSON[modelName].forEach(function(record) {
        if (relationshipType === "belongsTo") {
          return ids.push(record[relatedModel.attributize() + "_id"]);
        } else {
          return $.merge(ids, record[relatedModel.attributize() + "_ids"]);
        }
      });
      return uniqueArray(ids);
    };
    getRelatedModels = function(modelName) {
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
        return getRelatedModels(relatedModel);
      });
    };
    getNextFixtureID = function(modelName) {
      return ++config.fixtures[modelName.fixtureize()].slice(0).sort(function(a, b) {
        return b.id - a.id;
      })[0].id;
    };
    setDefaultValues = function(request, modelName) {
      var record;
      record = JSON.parse(request.data)[modelName.attributize()];
      return setRecordDefaults(record, modelName);
    };
    setRecordDefaults = function(record, modelName) {
      var factory, relationships;
      record.id = getNextFixtureID(modelName);
      modelName.modelize();
      factory = getFactory(modelName);
      relationships = getRelationships(modelName);
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
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var new_record, queryParams, requestType, rootModelName;
        responseJSON = {};
        requestType = getRequestType(request);
        rootModelName = getModelName(request);
        queryParams = getQueryParams(request);
        if (requestType === "post") {
          new_record = setDefaultValues(request, rootModelName);
          console.log(new_record);
          buildResponseJSON(rootModelName, queryParams);
        } else if (requestType === "get") {
          buildResponseJSON(rootModelName, queryParams);
          this.responseText = responseJSON;
        }
        if ($.mockjaxSettings.logging) {
          return console.log("MOCK RSP:", request.url, this.responseText);
        }
      }
    });
  };
})(jQuery);

//# sourceMappingURL=jquery.ember-mockjax.js.map
