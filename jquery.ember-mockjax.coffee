(($) ->

  $.emberMockJax = (options) ->

    # defaults
    config =
      fixtures: {}
      urls: ["*"]
      debug: false

    settings = $.extend settings, options

    log = (msg) ->
      console?.log msg if settings.debug

    parseUrl = (url) ->
      parser = document.createElement('a')
      parser.href = url
      parser

    findRecords = (fixtures, fixtureName, queryParams, requestData) ->
      fixtures[fixtureName].filter (element, index) ->
        matches = 0
        for param in queryParams
          continue unless requestData[param]
          if typeof requestData[param] is "object"
            if element[param.singularize()].toString() in requestData[param] or element[param.singularize()] in requestData[param]
              matches += 1
          else
            matches += 1 if requestData[param] = element[param]
        true if matches == queryParams.length

    uniqueArray = (arr) ->
      arr = arr.map (k) -> k.toString()
      $.grep arr, (v, k) ->
        $.inArray(v ,arr) == k

    sideloadRecords = (fixtures, name, parent) ->
      temp = []
      params = []
      res = []
      parent.forEach (record) ->
        $.merge(res, record[name.singularize() + "_ids"])

      params["ids"] = uniqueArray res
      findRecords(fixtures,name.capitalize(),["ids"],params)

    addRelatedRecord = (fixtures, json, name, new_record, singleResourceName) ->
      json[name.resourceize()] = [] unless typeof json[name.resourceize()] is "object"
      duplicated_record = $.extend(true, {}, fixtures[name.fixtureize()].slice(-1).pop())
      duplicated_record.id = parseInt(duplicated_record.id) + 1
      $.extend(duplicated_record,new_record[singleResourceName][name + "_attributes"])
      fixtures[name.fixtureize()].push(duplicated_record)
      delete new_record[singleResourceName][name + "_attributes"]
      new_record[singleResourceName][name + "_id"] = duplicated_record.id
      json[name.resourceize()].push(duplicated_record)
      json

    addRecord = (fixtures, json, new_record, fixtureName, resourceName, singleResourceName) ->
      duplicated_record = $.extend(true, {}, fixtures[fixtureName].slice(-1).pop())
      duplicated_record.id = parseInt(duplicated_record.id) + 1
      $.extend(duplicated_record, new_record[singleResourceName])
      fixtures[fixtureName].push(duplicated_record)
      json[resourceName].push(duplicated_record)
      json

    String::fixtureize = ->
      this.camelize().capitalize().pluralize() if typeof name is "string"

    String::resourceize = ->
      this.pluralize().underscore() if typeof name is "string"

    $.mockjax
      url: "*"
      responseTime: 0
      response: (request) ->

        queryParams             = []
        json                    = {}

        requestType             = request.type.toLowerCase()
        pathObject              = parseUrl(request.url)["pathname"].split("/")
        modelName               = pathObject.slice(-1).pop()
        putId                   = null

        if /^[0-9]+$/.test modelName
          if requestType is "get"
            request.data = {} if typeof request.data is "undefined"
            request.data.ids = [modelName]

          if requestType is "put"
            putId = modelName

          modelName = pathObject.slice(-2).shift().singularize().camelize().capitalize()

        else
          modelName = modelName.singularize().camelize().capitalize()

        fixtureName             = modelName.fixtureize()
        resourceName            = modelName.resourceize()
        singleResourceName      = resourceName.singularize()
        emberRelationships      = Ember.get(App[modelName], "relationshipsByName")
        fixtures                = settings.fixtures
        queryParams             = Object.keys(request.data) if typeof request.data is "object"
        modelAttributes         = Object.keys(App[modelName].prototype).filter (e) ->
                                    true unless e is "constructor" or e in emberRelationships.keys.list

        if requestType is "post"
          new_record = JSON.parse(request.data)
          json[resourceName] = []
          emberRelationships.forEach (name,relationship) ->
            if "nested" in Object.keys(relationship.options)
              unless relationship.options.async
                json = addRelatedRecord(fixtures,json,name,new_record,singleResourceName)

          @responseText = addRecord(fixtures,json,new_record,fixtureName,resourceName,singleResourceName)

        if requestType is "put"
          new_record = JSON.parse(request.data)
          json[resourceName] = []
          emberRelationships.forEach (name,relationship) ->
            if "nested" in Object.keys(relationship.options)
              unless relationship.options.async
                fixtures[name.fixtureize()].forEach (record) ->
                  if record.id is parseInt(new_record[singleResourceName][name + "_attributes"].id)
                    $.extend(record, new_record[singleResourceName][name + "_attributes"])
                    json[name.resourceize()] = [] if typeof json[name.resourceize()] is "undefined"
                    json[name.resourceize()].push(record)
                delete new_record[singleResourceName][name + "_attributes"]

          fixtures[fixtureName].forEach (record) ->
            if record.id is parseInt(putId)
              json[resourceName] = [] if typeof json[resourceName] is "undefined"
              $.extend(record, new_record[singleResourceName])
              json[resourceName].push(record)

          @responseText = json


        if requestType is "get"
          console.warn("Fixtures not found for Model : #{modelName}") unless fixtures[fixtureName]
          if queryParams.length
            json[resourceName] = findRecords(fixtures,fixtureName,queryParams,request.data)
          else
            json[resourceName] = fixtures[fixtureName]

          emberRelationships.forEach (name,relationship) ->
            # async = false / sideload records
            if "async" in Object.keys(relationship.options)
              unless relationship.options.async
                json[name] = sideloadRecords(fixtures,name,json[resourceName])

          @responseText = json

        console.log "MOCKJAX RESPONSE:", @responseText
  null
) jQuery

# if keys.length

#           # select records from settings.fixtures using attributes
#           # find('modelName', id: 1, active:true, type: "subscriber")
#           # find ('modeName', ids: [1,2,3])
#           payload[object] =
#             json_data.filter (e,i) ->
#               for k in keys
#                 matches = 0
#                 if k is "active"
#                   e[k] = true unless e.hasOwnProperty(k)
#                 mobject.data[k] = [mobject.data[k]] unless typeof mobject.data[k] == "object"
#                 e[k.singularize()] = e[k.singularize()].toString() if typeof e[k.singularize()] == "number"
#                 matches += 1 if mobject.data[k].indexOf(e[k.singularize()]) != -1
#               e if matches == keys.length

#           # sideload models with hasMany, nested: true and async: false relationships
#           # https://github.com/emberjs/data/issues/1426
#           relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
#           relations.forEach (modelName,relationship) ->
#             if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
#               payload[modelName] = [] unless payload[modelName]
#               ids = []

#               payload[object].map (e,i) ->
#                 $.merge ids, e[modelName.singularize() + "_ids"]

#               ids = $.unique ids
#               payload[modelName] =
#                 settings.fixtures[modelName].filter (element,index) ->
#                   element if ids.indexOf parseInt(element.id, 10) > -1



# $.emberMockJax()

# $("body").emberMockjax()

# # Reference jQuery
# $ = jQuery

# # Adds plugin object to jQuery
# $.fn.extend
#   # Change pluginName to your plugin's name.
#   emberMockjax: (options) ->
#     console.log options
#     # Default settings
#     settings =
#       fixtures: []
#       urls: []
#       debug: false

#     # Merge default settings with options.
#     settings = $.extend settings, options

#     # Simple logger.
#     log = (msg) ->
#       console?.log msg if settings.debug

#     # Mock all the things!
#     $.mockjax
#       url: "*"
#       responseTime: 0
#       response: (mobject) ->
#         url = mobject.url.replace('/','').slice(1).split('/')
#         object = url.shift()
#         type = mobject.type
#         mobject.data = [] unless mobject.data
#         payload = {}
#         json_data = settings.fixtures[object]

#         # error if fixture for model is not found
#         unless json_data
#           console.warn "MOCK FIXTURES NOT FOUND FOR " + object if window.console and console.log
#           return

#         # parse mockjax data
#         if type == "POST" or type == "PUT"
#           parsed_mockjax = JSON.parse(mobject.data)[object.singularize()]

#         # add record to settings.fixtures
#         # return record merged into a copy of previous record
#         if type == "POST"
#           last_record = $.extend(true, {}, json_data[json_data.length-1])
#           last_record.id = parseInt(last_record.id)+1

#           # go through all of the relationships and remove async:false, nested: true relationships
#           # create related models
#           # assign ids to parsed_mockjax
#           relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
#           relations.forEach (modelName,relationship) ->
#             if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
#               payload[modelName] = []

#               last_related_record = $.extend(true, {}, settings.fixtures[modelName][settings.fixtures[modelName].length-1])
#               record_id = parseInt(last_related_record.id)
#               parsed_mockjax[modelName.singularize()+"_ids"] = []
#               parsed_mockjax[modelName+"_attributes"].forEach (model,index) ->
#                 new_record = $.extend(last_related_record,model)
#                 record_id += 1
#                 last_related_record.id = record_id
#                 settings.fixtures[modelName].push(new_record)
#                 parsed_mockjax[modelName.singularize()+"_ids"].push(new_record.id)
#                 payload[modelName].push(new_record)
#                 console.log "MOCK CREATE EMBEDDED: ", new_record if window.console and console.log
#               parsed_mockjax[modelName+"_attributes"] = undefined

#           #default to active for new records
#           parsed_mockjax['active'] = true

#           $.extend(last_record, parsed_mockjax)
#           json_data.push(last_record)
#           payload[object] = [last_record]
#           @responseText = payload
#           return

#         # update fixture by merging mockjax data with existing record
#         if type == "PUT"
#           id = url.pop()
#           for o in json_data
#             if o.id.toString() == id.toString()

#               # update embedded relationships and sideload them
#               relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
#               relations.forEach (modelName,relationship) ->
#                 if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
#                   payload[modelName] = []
#                   parsed_mockjax[modelName+"_attributes"].forEach (model,index) ->
#                     settings.fixtures[modelName].forEach (model2,index2) ->
#                       if model.id.toString() == model2.id.toString()
#                         $.extend(model2,model)
#                         payload[modelName].push(model2)
#                   parsed_mockjax[modelName+"_attributes"] = undefined

#               payload[object] = [$.extend(o, parsed_mockjax)]
#               @responseText = payload
#           return

#         # add id to keys
#         if url.length
#           mobject.data["ids"] = [url.pop()]

#         # get custom attributes
#         keys = Object.keys(mobject.data)

#         # return active records by default (unless otherwise specified)
#         if keys.indexOf("active") < 0 and keys.indexOf("ids") < 0
#           keys = ["active"]
#           mobject.data["active"] = true

#         # Parse settings.fixtures with custom attributes (i.e. active: true)
#         if keys.length

#           # select records from settings.fixtures using attributes
#           # find('modelName', id: 1, active:true, type: "subscriber")
#           # find ('modeName', ids: [1,2,3])
#           payload[object] =
#             json_data.filter (e,i) ->
#               for k in keys
#                 matches = 0
#                 if k is "active"
#                   e[k] = true unless e.hasOwnProperty(k)
#                 mobject.data[k] = [mobject.data[k]] unless typeof mobject.data[k] == "object"
#                 e[k.singularize()] = e[k.singularize()].toString() if typeof e[k.singularize()] == "number"
#                 matches += 1 if mobject.data[k].indexOf(e[k.singularize()]) != -1
#               e if matches == keys.length

#           # sideload models with hasMany, nested: true and async: false relationships
#           # https://github.com/emberjs/data/issues/1426
#           relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
#           relations.forEach (modelName,relationship) ->
#             if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
#               payload[modelName] = [] unless payload[modelName]
#               ids = []

#               payload[object].map (e,i) ->
#                 $.merge ids, e[modelName.singularize() + "_ids"]

#               ids = $.unique ids
#               payload[modelName] =
#                 settings.fixtures[modelName].filter (element,index) ->
#                   element if ids.indexOf parseInt(element.id, 10) > -1
#         else
#           # return all fixture records
#           payload[object] = json_data

#         # send response to console for debugging
#         console.log "MOCK RESPONSE: " + mobject.url, payload if window.console and console.log

#         @responseText = payload