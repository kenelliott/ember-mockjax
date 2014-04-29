App = window.App = Em.Application.create()

App.ApplicationStore = DS.Store.extend
  init: ->
    @_super()
    App.store = @

App.ApplicationAdapter = DS.ActiveModelAdapter.extend()

# Fix for embeding hasMany relationships
# https://github.com/emberjs/data/issues/1426
DS.ActiveModelSerializer.reopen
  _embedKey: (key) ->
    @keyForAttribute key

  _nestedKey: (key) ->
    @keyForAttribute(key) + "_attributes"

  _serializeRelation: (record, key) ->
    Em.get(record, key).map ((relation) ->
      data = undefined
      primaryKey = undefined
      data = relation.serialize()
      primaryKey = Em.get(this, "primaryKey")
      data[primaryKey] = Em.get(relation, primaryKey)
      relation.transitionTo "saved"
      data
    ), this

  # Serialize has-many relationship
  serializeHasMany: (record, json, relationship) ->
    attrs = undefined
    embed = undefined
    embed_ids = undefined
    key = undefined
    nested = undefined
    key = relationship.key
    return unless record.get(key).isFulfilled or record.get(key).isLoaded
    attrs = Em.get(this, "attrs")
    embed = attrs and attrs[key] and attrs[key].embedded is "always"
    nested = relationship.options.nested
    embed_ids = attrs and attrs[key] and attrs[key].embedded is "ids"
    return json[@_embedKey(key)] = @_serializeRelation(record, key)  if embed
    return json[@_nestedKey(key)] = @_serializeRelation(record, key)  if nested
    if embed_ids
      json[@keyForRelationship(key, relationship.kind)] = Em.get(record, key).map((relation) ->
        relation.get "id"
      , this)

  serializeBelongsTo: (record, json, relationship) ->
    nested = undefined
    key = relationship.key
    nested = relationship.options.nested
    belongsTo = Em.get(record, key)
    key = (if @keyForRelationship then @keyForRelationship(key, "belongsTo") else key)
    if Em.isNone(belongsTo)
      json[key] = belongsTo
    else
      return json[key.replace("_id", "") + "_attributes"] = record.get(relationship.key).serialize(includeId:true) if nested
      json[key] = Em.get(belongsTo, "id")
    @serializePolymorphicType record, json, relationship  if relationship.options.polymorphic

App.find = (modelName, attrs = {}) ->
  App.store.find(modelName, attrs).then (res) ->
    console.log res.get("content")