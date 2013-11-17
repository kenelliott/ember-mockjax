# Reference jQuery
$ = jQuery

# Adds plugin object to jQuery
$.fn.extend
  # Change pluginName to your plugin's name.
  emberMockjax: (options) ->
    # Default settings
    settings =
      fixtures: []
      urls: []
      debug: false

    # Merge default settings with options.
    settings = $.extend settings, options

    # Simple logger.
    log = (msg) ->
      console?.log msg if settings.debug

    # Mock all the things!
    $.mockjax
      url: "*"
      responseTime: 0
      response: (mobject) ->
        url = mobject.url.replace('/','').slice(1).split('/')
        object = url.shift()
        type = mobject.type
        mobject.data = [] unless mobject.data
        payload = {}
        json_data = settings.fixtures[object]

        # error if fixture for model is not found
        unless json_data
          console.warn "MOCK FIXTURES NOT FOUND FOR " + object if window.console and console.log
          return

        # parse mockjax data
        if type == "POST" or type == "PUT"
          parsed_mockjax = JSON.parse(mobject.data)[object.singularize()]

        # add record to settings.fixtures
        # return record merged into a copy of previous record
        if type == "POST"
          last_record = $.extend(true, {}, json_data[json_data.length-1])
          last_record.id = parseInt(last_record.id)+1

          # go through all of the relationships and remove async:false, nested: true relationships
          # create related models
          # assign ids to parsed_mockjax
          relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
          relations.forEach (modelName,relationship) ->
            if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
              payload[modelName] = []

              last_related_record = $.extend(true, {}, settings.fixtures[modelName][settings.fixtures[modelName].length-1])
              record_id = parseInt(last_related_record.id)
              parsed_mockjax[modelName.singularize()+"_ids"] = []
              parsed_mockjax[modelName+"_attributes"].forEach (model,index) ->
                new_record = $.extend(last_related_record,model)
                record_id += 1
                last_related_record.id = record_id
                settings.fixtures[modelName].push(new_record)
                parsed_mockjax[modelName.singularize()+"_ids"].push(new_record.id)
                payload[modelName].push(new_record)
                console.log "MOCK CREATE EMBEDDED: ", new_record if window.console and console.log
              parsed_mockjax[modelName+"_attributes"] = undefined

          #default to active for new records
          parsed_mockjax['active'] = true

          $.extend(last_record, parsed_mockjax)
          json_data.push(last_record)
          payload[object] = [last_record]
          @responseText = payload
          return

        # update fixture by merging mockjax data with existing record
        if type == "PUT"
          id = url.pop()
          for o in json_data
            if o.id.toString() == id.toString()

              # update embedded relationships and sideload them
              relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
              relations.forEach (modelName,relationship) ->
                if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
                  payload[modelName] = []
                  parsed_mockjax[modelName+"_attributes"].forEach (model,index) ->
                    settings.fixtures[modelName].forEach (model2,index2) ->
                      if model.id.toString() == model2.id.toString()
                        $.extend(model2,model)
                        payload[modelName].push(model2)
                  parsed_mockjax[modelName+"_attributes"] = undefined

              payload[object] = [$.extend(o, parsed_mockjax)]
              @responseText = payload
          return

        # add id to keys
        if url.length
          mobject.data["ids"] = [url.pop()]

        # get custom attributes
        keys = Object.keys(mobject.data)

        # return active records by default (unless otherwise specified)
        if keys.indexOf("active") < 0 and keys.indexOf("ids") < 0
          keys = ["active"]
          mobject.data["active"] = true

        # Parse settings.fixtures with custom attributes (i.e. active: true)
        if keys.length

          # select records from settings.fixtures using attributes
          # find('modelName', id: 1, active:true, type: "subscriber")
          # find ('modeName', ids: [1,2,3])
          payload[object] =
            json_data.filter (e,i) ->
              for k in keys
                matches = 0
                if k is "active"
                  e[k] = true unless e.hasOwnProperty(k)
                mobject.data[k] = [mobject.data[k]] unless typeof mobject.data[k] == "object"
                e[k.singularize()] = e[k.singularize()].toString() if typeof e[k.singularize()] == "number"
                matches += 1 if mobject.data[k].indexOf(e[k.singularize()]) != -1
              e if matches == keys.length

          # sideload models with hasMany, nested: true and async: false relationships
          # https://github.com/emberjs/data/issues/1426
          relations = Ember.get(App[object.camelize().singularize().capitalize()], 'relationshipsByName')
          relations.forEach (modelName,relationship) ->
            if relationship.kind == "hasMany" and relationship.options.nested and not relationship.options.async
              payload[modelName] = [] unless payload[modelName]
              ids = []

              payload[object].map (e,i) ->
                $.merge ids, e[modelName.singularize() + "_ids"]

              ids = $.unique ids
              payload[modelName] =
                settings.fixtures[modelName].filter (element,index) ->
                  element if ids.indexOf parseInt(element.id, 10) > -1
        else
          # return all fixture records
          payload[object] = json_data

        # send response to console for debugging
        console.log "MOCK RESPONSE: " + mobject.url, payload if window.console and console.log

        @responseText = payload