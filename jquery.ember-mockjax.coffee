# add configuration params for nested_params

(($) ->
  $.emberMockJax = (options) ->
    responseJSON = {}

    # defaults
    config =
      fixtures: {}
      factories: {}
      urls: ["*"]
      debug: false
      namespace: ""
      scope_prefix: "by"
      nested_suffix: "attributes"
      delete_attribute: "_delete"

    $.mockjaxSettings.logging = true

    $.extend config, options

    log = (msg, obj) ->
      if !obj
        obj = msg
        msg = "no message"

    error = (msg) ->
      console?.error "jQuery-Ember-MockJax ERROR: #{msg}"

    uniqueArray = (arr) ->
      arr = arr.map (k) ->
        k.toString() unless k is null
      $.grep arr, (v, k) ->
        $.inArray(v ,arr) == k

    getRequestType = (request) ->
      request.type.toLowerCase()

    splitUrl = (url) ->
      url.replace("/#{config.namespace}","").split("/")

    getModelName = (request) ->
      splitUrl(request.url).shift()

    getQueryParams = (request) ->
      id = splitUrl(request.url)[1]
      if getRequestType(request) is "put"
        request.data = JSON.parse(request.data)
        modelName = getModelName(request).attributize()
        request.data[modelName].id = parseInt(id) if id
        request.data = JSON.stringify(request.data)
      else
        request.data = [] if !request.data
        request.data.id = parseInt(id) if id

      request.data

    getRelationships = (modelName) ->
      Em.get(App[modelName.modelize()], "relationshipsByName")

    String::fixtureize = ->
      @pluralize().camelize().capitalize()

    String::resourceize = ->
      @pluralize().underscore()

    String::modelize = ->
      @singularize().camelize().capitalize()

    String::attributize = ->
      @singularize().underscore()

    findRecords = (modelName, params) ->
      fixtureName = modelName.fixtureize()
      error("Fixtures not found for Model : #{fixtureName}") unless config.fixtures[fixtureName]
      config.fixtures[fixtureName].filter (record) ->
        for param of params
          continue unless params.hasOwnProperty(param)
          if record[param] isnt params[param] and record[param]?
            return false
          else if param is "ids" and params[param].indexOf(record.id.toString()) < 0
            return false
        true

    buildResponseJSON = (modelName, queryParams) ->
      responseJSON[modelName] = findRecords(modelName, queryParams)
      getRelatedRecords(modelName)

    getRelationshipIds = (modelName, relatedModel, relationshipType) ->
      ids = []
      responseJSON[modelName].forEach (record) ->
        if relationshipType is "belongsTo"
          ids.push record["#{relatedModel.attributize()}_id"]
        else
          $.merge(ids, record["#{relatedModel.attributize()}_ids"])
      uniqueArray ids

    getRelatedRecords = (modelName) ->
      relationships = getRelationships(modelName)
      relationships.forEach (relatedModel, relationship) ->
        return if !relationship.options.async? or relationship.options.async is true
        params = []
        params["ids"] = getRelationshipIds(modelName, relatedModel, relationship.kind)
        responseJSON[relatedModel.resourceize()] = findRecords(relatedModel, params) 
        getRelatedRecords(relatedModel)

    getNextFixtureID = (modelName) ->
      config.fixtures[modelName.fixtureize()].slice(0).sort((a,b) -> b.id - a.id)[0].id + 1

    setDefaultValues = (request, modelName) ->
      record = JSON.parse(request.data)[modelName.attributize()]
      setRecordDefaults(record, modelName)

    setRecordDefaults = (record, modelName) ->
      modelName.modelize()
      factory = getFactory(modelName)
      Object.keys(record).forEach (key) ->
        prop = record[key]
        def = factory[key.camelize()]?.default
        if typeof prop is "object" and prop is null and def
          record[key] = def
        else if typeof prop is "object" and prop isnt null
          record[key] = setRecordDefaults(record[key], key.replace("_attributes",""))
      record

    getFactory = (modelName) ->
      config.factories[modelName.fixtureize()]

    removeIgnoredAttributes = (modelName, record) ->
      factory = getFactory(modelName)
      Object.keys(factory).forEach (attr) ->
        delete record[attr.attributize()] if factory[attr].ignore
      relationships = getRelationships(modelName)
      relationships.forEach (relatedModelName, relationship) ->
        attributeName = if relationship.kind is "hasMany" then relatedModelName.resourceize() else relatedModelName.attributize()
        attributeName += "_attributes"
        removeIgnoredAttributes(relatedModelName, record[attributeName]) if record[attributeName]?

    addRelatedRecordsToFixtures = (modelName, record) ->
      removeIgnoredAttributes(modelName, record)
      relationships = getRelationships(modelName)
      record.id = getNextFixtureID(modelName)

      relationships.forEach (relatedModelName, relationship) ->
        attributeName = if relationship.kind is "hasMany" then relatedModelName.resourceize() else relatedModelName.attributize()
        attributeName += "_attributes"
        if relationship.options.nested and record[attributeName]?
          if relationship.kind is "hasMany"
            record["#{relatedModelName}_ids"] = []
            record[attributeName].forEach (relatedRecord) ->
              if !relatedRecord.id
                relatedRecord.id = getNextFixtureID(modelName)
                record["#{relatedModelName}_ids"].push addRecordToFixtures(relatedModelName, relatedRecord)
              else
                $.extend(getFixtureById(relatedModelName, record[attributeName].id), relatedRecord)
          else 
            if !record[attributeName].id
              record[attributeName].id = getNextFixtureID(relatedModelName)
              record["#{relatedModelName}_id"] = addRecordToFixtures(relatedModelName, record[attributeName])
            else
              record["#{relatedModelName}_id"] = record[attributeName].id
              fixture = getFixtureById(relatedModelName, record[attributeName].id)
              $.extend(fixture, record[attributeName])

          delete record[attributeName]

    addRecordToFixtures = (modelName, record) ->
      config.fixtures[modelName.fixtureize()].push(record)
      record.id

    getFixtureById = (fixtureName, id) ->
      config.fixtures[fixtureName.fixtureize()].filterBy("id", parseInt(id)).get("firstObject")

    $.mockjax
      url: "*"
      responseTime: 0
      response: (request) ->
        responseJSON    = {}
        requestType     = getRequestType(request)
        rootModelName   = getModelName(request)

        if requestType is "post"
          newRecord = setDefaultValues(request, rootModelName)
          addRelatedRecordsToFixtures(rootModelName, newRecord)
          id = addRecordToFixtures(rootModelName, newRecord)
          queryParams = []
          queryParams.id = id
          buildResponseJSON(rootModelName, queryParams)
        else if requestType is "put"
          queryParams = getQueryParams(request)
          updateRecord = JSON.parse(queryParams)[rootModelName.attributize()]
          updateFixture = getFixtureById(rootModelName, updateRecord.id)
          addRelatedRecordsToFixtures(rootModelName, updateRecord)
          addRecordToFixtures(rootModelName, updateRecord)
          queryParams = []
          queryParams.id = updateRecord.ids
          buildResponseJSON(rootModelName, queryParams)
        else if requestType is "get"
          queryParams = getQueryParams(request)
          buildResponseJSON(rootModelName, queryParams)

        @responseText = responseJSON

        console.log "MOCK RSP:", request.url, @responseText if $.mockjaxSettings.logging

) jQuery