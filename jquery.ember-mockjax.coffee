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

    settings = $.extend config, options

    log = (msg, obj) ->
      if !obj
        obj = msg
        msg = "no message"

    error = (msg) ->
      console?.error "jQuery-Ember-MockJax ERROR: #{msg}"

    # parseUrl = (url) ->
    #   parser = document.createElement('a')
    #   parser.href = url
    #   parser

    uniqueArray = (arr) ->
      arr = arr.map (k) ->
        k.toString() unless k is null
      $.grep arr, (v, k) ->
        $.inArray(v ,arr) == k

    # addRelatedRecord = (fixtures, json, name, new_record, singleResourceName) ->
    #   json[name.resourceize()] = [] if typeof json[name.resourceize()] isnt "object"
    #   duplicated_record = $.extend(true, {}, fixtures[name.fixtureize()].slice(-1).pop())
    #   duplicated_record.id = parseInt(duplicated_record.id) + 1
    #   $.extend(duplicated_record,new_record[singleResourceName][name.underscore() + "_attributes"])
    #   fixtures[name.fixtureize()].push(duplicated_record)
    #   delete new_record[singleResourceName][name.underscore() + "_attributes"]
    #   new_record[singleResourceName][name.underscore().singularize() + "_id"] = duplicated_record.id
    #   json[name.resourceize()].push(duplicated_record)
    #   json

    # addRelatedRecords = (fixtures, json, name, new_record, singleResourceName) ->
    #   duplicated_record = undefined
    #   json[name.resourceize()] = []  if typeof json[name.resourceize()] isnt "object"
    #   new_record[singleResourceName][name.resourceize().singularize() + "_ids"] = []
    #   new_record[singleResourceName][name.resourceize() + "_attributes"].forEach (record) ->
    #     duplicated_record = $.extend(true, {}, fixtures[name.fixtureize()].slice(-1).pop())
    #     delete record.id

    #     $.extend duplicated_record, record
    #     duplicated_record.id = parseInt(duplicated_record.id) + 1
    #     fixtures[name.fixtureize()].push duplicated_record
    #     new_record[singleResourceName][name.resourceize().singularize() + "_ids"].push duplicated_record.id
    #     json[name.resourceize()].push duplicated_record
    #     return

    #   delete new_record[singleResourceName][name.resourceize() + "_attributes"]

    #   json

    # allPropsNull = (obj,msg) ->
    #   Object.keys(obj).every (key) ->
    #     if obj[key] isnt null and key not in ["archived", "type", "primary", "quantity"]
    #       allPropsNull obj[key] if typeof obj[key] is "object"
    #     else
    #       true

    # flattenObject = (obj,result) ->
    #   result = {} unless result
    #   keys = Object.keys(obj)
    #   keys.forEach (key) ->
    #     if obj[key] is null
    #       delete obj[key]
    #     else if typeof obj[key] is "object"
    #       result = flattenObject(obj[key],result)
    #     else
    #       result[key] = [obj[key]]
    #   result

    # setErrorMessages = (obj, msg, parentKeys) ->
    #   unless parentKeys
    #       parentKeys = []
    #       path = ""

    #   Object.keys(obj).every (key) ->
    #     if obj[key] isnt null and typeof obj[key] isnt "boolean"
    #       if typeof obj[key] is "object"
    #         parentKeys.push(key.replace("_attributes",""))
    #         obj[key] = setErrorMessages(obj[key], msg, parentKeys)
    #     else
    #       path = parentKeys.join(".") + "." if parentKeys.length
    #       obj["#{path}#{key}"] = "#{msg}"
    #   obj

    # buildErrorObject = (obj, msg) ->
    #   rootKey = Object.keys(obj).pop()
    #   obj["errors"] = flattenObject(setErrorMessages(obj[rootKey],msg))
    #   delete obj[rootKey]
    #   obj

    # sideloadRecords = (fixtures, name, parent, kind) ->
    #   temp = []
    #   params = []
    #   res = []
    #   parent.forEach (record) ->
    #     if kind is "belongsTo"
    #       res.push record[name.underscore().singularize() + "_id"]
    #     else
    #       $.merge(res, record[name.underscore().singularize() + "_ids"])

    #   params["ids"] = uniqueArray res
    #   records = findRecords(fixtures,name.capitalize().pluralize(),["ids"],params)

    # getRelatedModels = (resourceName, json) ->
    #   relationships = getRelationships(resourceName.modelize())
    #   relationships.forEach (name, relationship) ->
    #     if "async" in Object.keys(relationship.options)
    #       unless relationship.options.async
    #         json[name.pluralize()] = sideloadRecords(fixtures,name,json[resourceName],relationship.kind)
    #         getRelatedModels(name, fixtures, json)
    #   json

    getRequestType = (request) ->
      request.type.toLowerCase()

    getModelName = (request) ->
      request.url.replace("/#{config.namespace}","").split("/").shift()

    getQueryParams = (request) ->
      Object.keys(request.data) if typeof request.data is "object"

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
          if record[param] isnt params[param] and record[param]?
            return false
        true

    buildResponseJSON = (modelName, queryParams) ->
      responseJSON[modelName] = findRecords(modelName, queryParams)
      getRelatedModels(modelName)

    getRelationshipIds = (modelName, relatedModel, relationshipType) ->
      ids = []
      responseJSON[modelName].forEach (record) ->
        if relationshipType is "belongsTo"
          ids.push record[relatedModel.attributize() + "_id"]
        else
          $.merge(ids, record[relatedModel.attributize() + "_ids"])
      uniqueArray ids

    getRelatedModels = (modelName) ->
      relationships = getRelationships(modelName)
      relationships.forEach (relatedModel, relationship) ->
        return if !relationship.options.async? or relationship.options.async is true
        params = []
        params["ids"] = getRelationshipIds(modelName, relatedModel, relationship.kind)
        responseJSON[relatedModel.resourceize()] = findRecords(relatedModel, params) 
        getRelatedModels(relatedModel)

    getNextFixtureID = (modelName) ->
        ++config.fixtures[modelName.fixtureize()].slice(0).sort((a,b) -> b.id - a.id)[0].id

    setDefaultValues = (request, modelName) ->
      record = JSON.parse(request.data)[modelName.attributize()]
      record.id = getNextFixtureID(modelName)
      setRecordDefaults(record, modelName)

    setRecordDefaults = (record, modelName) ->
      factory = getFactory(modelName)
      relationships = getRelationships(modelName)
      Object.keys(record).forEach (key) ->
        prop = record[key]
        def = factory[key.camelize()]?.default
        if typeof prop is "object" and prop is null and def
          record[key] = def
        else if typeof prop is "object" and prop isnt null
          console.log "prop", prop, key
        #   # setRecordDefaults(request, )
      record

    getFactory = (modelName) ->
      config.factories[modelName.fixtureize()]

    $.mockjax
      url: "*"
      responseTime: 0
      response: (request) ->
        responseJSON    = {}
        requestType     = getRequestType(request)
        rootModelName   = getModelName(request)
        queryParams     = getQueryParams(request)

        if requestType is "post"
          # check for missing properties

          new_record = setDefaultValues(request, rootModelName)
          # create records for nested attributes

          console.log new_record

          buildResponseJSON(rootModelName, queryParams)

        # addRecord = (fixtures, json, new_record, fixtureName, resourceName, singleResourceName) ->
        #   duplicated_record = $.extend(true, {}, fixtures[fixtureName].slice(-1).pop())
        #   duplicated_record.id = parseInt(duplicated_record.id) + 1
        #   duplicated_record.archived_at = null
        #   $.extend(duplicated_record, new_record[singleResourceName])
        #   fixtures[fixtureName].push(duplicated_record)
        #   json[resourceName].push(duplicated_record)
        #   json

        #   # return error object if all values are null
        #   if allPropsNull(new_record)
        #     @status = 422
        #     @responseText = buildErrorObject(new_record, "can't be blank")
        #   else
        #     json[resourceName] = []
        #     emberRelationships.forEach (name,relationship) ->
        #       if "nested" in Object.keys(relationship.options)
        #         unless relationship.options.async
        #           if relationship.kind is "hasMany"
        #             json = addRelatedRecords(fixtures,json,name,new_record,singleResourceName)
        #           else
        #             json = addRelatedRecord(fixtures,json,name,new_record,singleResourceName)

        #     @responseText = addRecord(fixtures,json,new_record,fixtureName,resourceName,singleResourceName)

        else if requestType is "get"
          buildResponseJSON(rootModelName, queryParams)
          @responseText = responseJSON

          # console.log modelName
          # findRecords(fixtureName)

          #   if queryParams.length
          #     json[resourceName] = findRecords(fixtures,fixtureName,queryParams,request.data)
          #   else
          #     json[resourceName] = fixtures[fixtureName]

          #   @responseText = getRelatedModels(resourceName, fixtures, json)

        # queryParams             = []
        # json                    = {}

        # requestType             = request.type.toLowerCase()
        # pathObject              = parseUrl(request.url)["pathname"].split("/")
        # modelName               = pathObject.slice(-1).pop()
        # putId                   = null

        # if /^[0-9]+$/.test modelName
        #   if requestType is "get"
        #     request.data = {} if typeof request.data is "undefined"
        #     request.data.ids = [modelName]

        #   if requestType is "put"
        #     putId = modelName

        #   modelName = pathObject.slice(-2).shift().modelize()

        # else
        #   modelName = modelName.modelize()

        # fixtureName             = modelName.fixtureize()
        # resourceName            = modelName.resourceize()
        # singleResourceName      = resourceName.singularize()
        # emberRelationships      = getRelationships(modelName)
        # fixtures                = settings.fixtures
        # queryParams             = Object.keys(request.data) if typeof request.data is "object"
        # modelAttributes         = Object.keys(App[modelName].prototype).filter (e) ->
        #                             true unless e is "constructor" or e in emberRelationships.keys.list

        # if requestType is "post"
        #   new_record = JSON.parse(request.data)

        #   # return error object if all values are null
        #   if allPropsNull(new_record)
        #     @status = 422
        #     @responseText = buildErrorObject(new_record, "can't be blank")
        #   else
        #     json[resourceName] = []
        #     emberRelationships.forEach (name,relationship) ->
        #       if "nested" in Object.keys(relationship.options)
        #         unless relationship.options.async
        #           if relationship.kind is "hasMany"
        #             json = addRelatedRecords(fixtures,json,name,new_record,singleResourceName)
        #           else
        #             json = addRelatedRecord(fixtures,json,name,new_record,singleResourceName)

        #     @responseText = addRecord(fixtures,json,new_record,fixtureName,resourceName,singleResourceName)

        # if requestType is "put"
        #   new_record = JSON.parse(request.data)
        #   json[resourceName] = []
        #   emberRelationships.forEach (name,relationship) ->
        #     if "nested" in Object.keys(relationship.options)
        #       unless relationship.options.async
        #         fixtures[name.fixtureize()].forEach (record) ->
        #           if record.id is parseInt(new_record[singleResourceName][name.underscore() + "_attributes"].id)
        #             $.extend(record, new_record[singleResourceName][name.underscore() + "_attributes"])
        #             json[name.resourceize()] = [] if typeof json[name.resourceize()] is "undefined"
        #             json[name.resourceize()].push(record)
        #         delete new_record[singleResourceName][name.underscore() + "_attributes"]

        #   fixtures[fixtureName].forEach (record) ->
        #     if record.id is parseInt(putId)
        #       json[resourceName] = [] if typeof json[resourceName] is "undefined"
        #       $.extend(record, new_record[singleResourceName])
        #       json[resourceName].push(record)

        #   @responseText = json

        # if requestType is "get"

        #   console.warn("Fixtures not found for Model : #{modelName}") unless fixtures[fixtureName]
        #   if queryParams.length
        #     json[resourceName] = findRecords(fixtures,fixtureName,queryParams,request.data)
        #   else
        #     json[resourceName] = fixtures[fixtureName]

        #   @responseText = getRelatedModels(resourceName, fixtures, json)

        console.log "MOCK RSP:", request.url, @responseText if $.mockjaxSettings.logging

) jQuery

# findRecords = (fixtures, fixtureName, queryParams, requestData) ->
#   fixtures[fixtureName].filter (element, index) ->
#     matches = 0
#     for param in queryParams
#       scope_param = param.replace "by_", ""
#       if typeof requestData[param] is "object" and requestData[param] isnt null
#         if element[scope_param.singularize()].toString() in requestData[param] or element[scope_param.singularize()] in requestData[param]
#           matches += 1
#       else
#         matchParam = requestData[param]
#         matchParam = parseInt(requestData[param]) if typeof requestData[param] is "string" and typeof element[scope_param.singularize()] is "number"
#         matches += 1 if matchParam == element[scope_param.singularize()]
#     true if matches == queryParams.length