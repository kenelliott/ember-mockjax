(function($) {
  return $.emberMockJax = function(options) {
    var addRecordToFixtures, addRelatedRecordsToFixtures, buildResponseJSON, config, error, findRecords, getFactory, getFixtureById, getModelName, getNextFixtureID, getQueryParams, getRelatedRecords, getRelationshipIds, getRelationships, getRequestType, log, removeIgnoredAttributes, responseJSON, setDefaultValues, setRecordDefaults, splitUrl, uniqueArray;
    responseJSON = {};
    config = {
      fixtures: {},
      factories: {},
      urls: ["*"],
      debug: false,
      namespace: ""
    };
    $.mockjaxSettings.logging = true;
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
    addRelatedRecordsToFixtures = function(modelName, record) {
      var relationships;
      removeIgnoredAttributes(modelName, record);
      relationships = getRelationships(modelName);
      record.id = getNextFixtureID(modelName);
      return relationships.forEach(function(relatedModelName, relationship) {
        var attributeName, fixture;
        attributeName = relationship.kind === "hasMany" ? relatedModelName.resourceize() : relatedModelName.attributize();
        attributeName += "_attributes";
        if (relationship.options.nested && (record[attributeName] != null)) {
          if (relationship.kind === "hasMany") {
            record["" + relatedModelName + "_ids"] = [];
            record[attributeName].forEach(function(relatedRecord) {
              if (!relatedRecord.id) {
                console.log("adding hasMany related record", relatedModelName, relatedRecord);
                relatedRecord.id = getNextFixtureID(modelName);
                return record["" + relatedModelName + "_ids"].push(addRecordToFixtures(relatedModelName, relatedRecord));
              } else {
                console.log("updating hasMany related record", relatedModelName, relatedRecord);
                return $.extend(getFixtureById(relatedModelName, record[attributeName].id), relatedRecord);
              }
            });
          } else {
            if (!record[attributeName].id) {
              console.log("adding belongsTo related record", relatedModelName, record[attributeName]);
              record[attributeName].id = getNextFixtureID(relatedModelName);
              record["" + relatedModelName + "_id"] = addRecordToFixtures(relatedModelName, record[attributeName]);
            } else {
              console.log("updating belongsTo related record", relatedModelName, record[attributeName]);
              record["" + relatedModelName + "_id"] = record[attributeName].id;
              fixture = getFixtureById(relatedModelName, record[attributeName].id);
              $.extend(fixture, record[attributeName]);
            }
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
      return config.fixtures[fixtureName.fixtureize()].filterBy("id", parseInt(id)).get("firstObject");
    };
    return $.mockjax({
      url: "*",
      responseTime: 0,
      response: function(request) {
        var id, newRecord, queryParams, requestType, rootModelName, updateFixture, updateRecord;
        responseJSON = {};
        requestType = getRequestType(request);
        rootModelName = getModelName(request);
        queryParams = getQueryParams(request);
        if (requestType === "post") {
          newRecord = setDefaultValues(request, rootModelName);
          addRelatedRecordsToFixtures(rootModelName, newRecord);
          id = addRecordToFixtures(rootModelName, newRecord);
          queryParams = [];
          queryParams.id = id;
          buildResponseJSON(rootModelName, queryParams);
          console.log(config.fixtures);
        } else if (requestType === "put") {
          updateRecord = JSON.parse(queryParams)[rootModelName.attributize()];
          updateFixture = getFixtureById(rootModelName, updateRecord.id);
          addRelatedRecordsToFixtures(rootModelName, updateRecord);
          addRecordToFixtures(rootModelName, updateRecord);
          queryParams = [];
          queryParams.id = updateRecord.ids;
          buildResponseJSON(rootModelName, queryParams);
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
