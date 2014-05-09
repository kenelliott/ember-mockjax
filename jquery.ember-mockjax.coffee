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
      scopePrefixes: ["by_", "has_"]
      nestedSuffix: "attributes"
      deleteAttribute: "_delete"

    $.extend config, options

    $.mockjaxSettings.logging = config.debug

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
      map = Ember.Map.create()
      App[modelName.modelize()].eachComputedProperty (name, meta) -> 
        if meta.isRelationship 
          map.set(name, meta) 
      map 

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
      console.log getRelatedFixtureIds("medals", "player", 1)
      error("Fixtures not found for Model : #{fixtureName}") unless config.fixtures[fixtureName]

      # /medals?by_player_id=1

      # for param in Object.keys(params)
      #   if param.match(prefixRegex)
      #     withoutPrefix = param.replace(prefixRegex, "")
      #     paramModel = withoutPrefix.replace("_id", "")
      #     if App[modelName.modelize()].hasOwnProperty(paramModel)
      #       relationships = getRelationships(modelName)
      #     else
      #       relationships = getRelationships(paramModel)
      #       params.ids = getRelationshipIds(paramModel, modelName, "hasMany", params[param])

      config.fixtures[fixtureName].filter (record) ->
        for param in Object.keys(params)
          continue unless params.hasOwnProperty(param)
          if record[param] isnt params[param] and record[param]?
            return false
          else if param is "ids" and params[param].indexOf(record.id.toString()) < 0
            return false
        true

    getRelatedFixtureIds = (model, subModel, subModelId) ->
      ids = []
      for record in config.fixtures[model.fixtureize()]
        if record["#{subModel.attributize()}_ids"] and subModelId in record["#{subModel.attributize()}_ids"]
          ids.push record.id # add player id to list
        else if record["#{subModel.attributize()}_id"] and record["#{subModel.attributize()}_id"] is subModelId
          ids.push record.id

      subModelRecord = getFixtureById(subModel, subModelId)
      if "#{model.attributize()}_ids" in subModelRecord
        $.merge(ids, record['#{model.attributize()}_ids'])
      else if "#{model.attributize()}_id" in subModelRecord
        ids.push record["#{model.attributize()}_id"]
      uniqueArray ids

    buildResponseJSON = (modelName, queryParams) ->
      responseJSON[modelName] = findRecords(modelName, queryParams)
      getSideloadedRecords(modelName)

    getRelationshipIds = (modelName, relatedModel, relationshipType) ->
      ids = []
      responseJSON[modelName].forEach (record) ->
        if relationshipType is "belongsTo"
          ids.push record["#{relatedModel.attributize()}_id"]
        else
          $.merge(ids, record["#{relatedModel.attributize()}_ids"])
      uniqueArray ids

    normalizeRequest = (request) -> 
      params = $.parseParams(request.url) 
      request.url = request.url.split("?")[0] 
      request.data = if request.data then $.merge(request.data, params) else params 
      request

    getSideloadedRecords = (modelName) ->
      relationships = getRelationships(modelName)
      relationships.forEach (relatedModel, relationship) ->
        return if !relationship.options.async? or relationship.options.async is true
        params = []
        params["ids"] = getRelationshipIds(modelName, relatedModel, relationship.kind)
        responseJSON[relatedModel.resourceize()] = findRecords(relatedModel, params) 
        getSideloadedRecords(relatedModel)

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

    addError = (errorObj, errorKey, error) ->
      errorObj.errors[errorKey] = [] unless errorObj.errors[errorKey]
      errorObj.errors[errorKey].push(error) 

    checkValidations = (errorObj, factory, key, value, prepend) ->
      validations = factory[key].validation
      return unless validations
      errorKey = if prepend then "#{prepend}.#{key}" else key
      # TODO: Custom error messages
      if validations.required and not value
        addError(errorObj, errorKey, "is required")
      if validations.matches and not validations.matches.test(value)
        addError(errorObj, errorKey, "is invalid")

    validate = (errorObj, modelName, record, prepend) ->
      modelName = modelName.modelize()
      attributes = Em.get(App[modelName],"attributes")
      relationships =  getRelationships(modelName)
      factory = getFactory(modelName.resourceize())
      return unless factory
      for key, value of record
        key = key.replace("_attributes","")
        if value? and typeof value is "object" and relationships.has(key)
          prependName = if prepend then "#{prepend}.#{key}" else key
          validate(errorObj, key, value, prependName)
        else if attributes.has(key)
          checkValidations(errorObj, factory, key, value, prepend)
      return true unless Object.keys(errorObj.errors).length > 0

    addRelatedFixtureRecords = (modelName, record, requestType) ->
      removeIgnoredAttributes(modelName, record)
      relationships = getRelationships(modelName)
      record.id = getNextFixtureID(modelName) unless requestType is "put"

      relationships.forEach (relatedModelName, relationship) ->
        attributeName = if relationship.kind is "hasMany" then relatedModelName.resourceize() else relatedModelName.attributize()
        attributeName += "_attributes"
        if relationship.options.nested and record[attributeName]?
          if relationship.kind is "hasMany"
            record["#{relatedModelName}_ids"] = []
            record[attributeName].forEach (relatedRecord) ->
              if !relatedRecord.id
                relatedRecord.id = getNextFixtureID(modelName)
                record["#{relatedModelName}_ids"].push addFixtureRecord(relatedModelName, relatedRecord)
              else
                relatedRecord.id = parseInt(relatedRecord.id)
                $.extend(getFixtureById(relatedModelName, record[attributeName].id), relatedRecord)
          else 
            if !record[attributeName].id
              record[attributeName].id = getNextFixtureID(relatedModelName)
              record["#{relatedModelName}_id"] = addFixtureRecord(relatedModelName, record[attributeName])
            else
              record["#{relatedModelName}_id"] = record[attributeName].id
              fixture = getFixtureById(relatedModelName, record[attributeName].id)
              record[attributeName].id = parseInt(record[attributeName].id)
              $.extend(fixture, record[attributeName])

          delete record[attributeName]
      record

    addFixtureRecord = (modelName, record) ->
      config.fixtures[modelName.fixtureize()].push(record)
      record.id

    getFixtureById = (fixtureName, id) ->
      config.fixtures[fixtureName.fixtureize()].filterBy("id", parseInt(id)).get("firstObject")

    $.mockjax
      url: "*"
      responseTime: 0
      response: (request) ->
        responseJSON    = {}
        request         = normalizeRequest(request)
        requestType     = getRequestType(request)
        rootModelName   = getModelName(request)
        errorObj        = errors:{}

        if requestType is "post"
          newRecord = setDefaultValues(request, rootModelName)
          unless validate(errorObj, rootModelName, newRecord)
            @responseText = errorObj
            @status = 422
            return
          addRelatedFixtureRecords(rootModelName, newRecord)
          id = addFixtureRecord(rootModelName, newRecord)
          queryParams = []
          queryParams.id = id
          buildResponseJSON(rootModelName, queryParams)
        else if requestType is "put"
          queryParams = getQueryParams(request)
          updateRecord = JSON.parse(queryParams)[rootModelName.attributize()]
          unless validate(errorObj, rootModelName, updateRecord)
            @responseText = errorObj
            @status = 422
            return
          updateFixture = getFixtureById(rootModelName, updateRecord.id)
          updateRecord = addRelatedFixtureRecords(rootModelName, updateRecord, requestType)
          queryParams = []
          $.extend(getFixtureById(rootModelName, updateRecord.id), updateRecord)
          queryParams.id = updateRecord.id
          buildResponseJSON(rootModelName, queryParams)
        else if requestType is "get"
          queryParams = getQueryParams(request)
          buildResponseJSON(rootModelName, queryParams)

        @responseText = responseJSON

        console.log "MOCK RSP:", request.url, @responseText if $.mockjaxSettings.logging

) jQuery

(($) ->
  re = /([^&=]+)=?([^&]*)/g
  decode = (str) ->
    decodeURIComponent str.replace(/\+/g, " ")

  $.parseParams = (query) ->
    createElement = (params, key, value) ->
      key = key + ""
      if key.indexOf(".") isnt -1
        list = key.split(".")
        new_key = key.split(/\.(.+)?/)[1]
        params[list[0]] = {}  unless params[list[0]]
        if new_key isnt ""
          createElement params[list[0]], new_key, value
        else
          console.warn "parseParams :: empty property in key \"" + key + "\""
      else if key.indexOf("[") isnt -1
        list = key.split("[")
        key = list[0]
        list = list[1].split("]")
        index = list[0]
        if index is ""
          params = {}  unless params
          params[key] = []  if not params[key] or not $.isArray(params[key])
          params[key].push value
        else
          params = {}  unless params
          params[key] = []  if not params[key] or not $.isArray(params[key])
          params[key][parseInt(index)] = value
      else
        params = {}  unless params
        params[key] = value
      return
    query = query + ""
    query = window.location + ""  if query is ""
    params = {}
    e = undefined
    if query
      query = query.substr(0, query.indexOf("#"))  if query.indexOf("#") isnt -1
      if query.indexOf("?") isnt -1
        query = query.substr(query.indexOf("?") + 1, query.length)
      else
        return {}
      return {}  if query is ""
      while e = re.exec(query)
        key = decode(e[1])
        value = decode(e[2])
        createElement params, key, value
    params

  return
) jQuery