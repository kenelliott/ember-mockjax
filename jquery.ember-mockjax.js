(function($) {
  return $.emberMockJax = function(options) {
    var addRecordToFixtures, addRelatedRecordsToFixtures, buildResponseJSON, config, error, findRecords, getFactory, getFixtureById, getModelName, getNextFixtureID, getQueryParams, getRelatedRecords, getRelationshipIds, getRelationships, getRequestType, log, responseJSON, setDefaultValues, setRecordDefaults, splitUrl, uniqueArray;
    responseJSON = {};
    config = {
      fixtures: {},
      factories: {},
      urls: ["*"],
      debug: false,
      namespace: ""
    };
    $.extend(config, options);
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
      var id;
      id = splitUrl(request.url)[1];
      if (!request.data) {
        request.data = [];
      }
      if (id) {
        request.data = {
          "id": parseInt(id)
        };
      }
      if (typeof request.data === "object") {
        return request.data;
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
      return getRelatedRecords(modelName);
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
    getRelatedRecords = function(modelName) {
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
        return getRelatedRecords(relatedModel);
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
    addRelatedRecordsToFixtures = function(modelName, record) {
      var relationships;
      relationships = getRelationships(modelName);
      return relationships.forEach(function(relatedModelName, relationship) {
        var attributeName;
        attributeName = relationship.kind === "hasMany" ? relatedModelName.resourceize() : relatedModelName.attributize();
        attributeName += "_attributes";
        if (relationship.options.nested && (record[attributeName] != null)) {
          if (relationship.kind === "hasMany") {
            record["" + relatedModelName + "_ids"] = [];
            record[attributeName].forEach(function(relatedRecord) {
              return record["" + relatedModelName + "_ids"].push(addRecordToFixtures(relatedModelName, relatedRecord));
            });
          } else {
            record["" + relatedModelName + "_id"] = addRecordToFixtures(relatedModelName, record[attributeName]);
          }
          return delete record[attributeName];
        }
      });
    };
    addRecordToFixtures = function(modelName, record) {
      config.fixtures[modelName.fixtureize()].push(record);
      return record.id;
    };
    getFixtureById = function(fixtureName, id) {
      return App.Fixtures[fixtureName].filterBy("id", id).get("firstObject");
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
          console.log("post");
          new_record = setDefaultValues(request, rootModelName);
          addRelatedRecordsToFixtures(rootModelName, new_record);
          addRecordToFixtures(rootModelName, new_record);
          buildResponseJSON(rootModelName, queryParams);
        } else if (requestType === "put") {
          console.log(queryParams);
        } else if (requestType === "get") {
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

//# sourceMappingURL=jquery.ember-mockjax.js.map
