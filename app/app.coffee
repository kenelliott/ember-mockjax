App = window.App = Ember.Application.create()

App.ApplicationAdapter = DS.ActiveModelAdapter.extend()

# Fix for embeding hasMany and belongsTo relationships
# https://github.com/emberjs/data/issues/1426
DS.ActiveModelSerializer.reopen
  _embedKey: (key) ->
    @keyForAttribute key

  _nestedKey: (key) ->
    @keyForAttribute(key) + "_attributes"

  _serializeRelation: (record, key) ->
    Ember.get(record, key).map ((relation) ->
      data = undefined
      primaryKey = undefined
      data = relation.serialize()
      primaryKey = Ember.get(this, "primaryKey")
      data[primaryKey] = Ember.get(relation, primaryKey)
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
    attrs = Ember.get(this, "attrs")
    embed = attrs and attrs[key] and attrs[key].embedded is "always"
    nested = relationship.options.nested
    embed_ids = attrs and attrs[key] and attrs[key].embedded is "ids"
    return json[@_embedKey(key)] = @_serializeRelation(record, key)  if embed
    return json[@_nestedKey(key)] = @_serializeRelation(record, key)  if nested
    if embed_ids
      json[@keyForRelationship(key, relationship.kind)] = Ember.get(record, key).map((relation) ->
        relation.get "id"
      , this)

  serializeBelongsTo: (record, json, relationship) ->
    nested = undefined
    key = relationship.key
    nested = relationship.options.nested
    belongsTo = Ember.get(record, key)
    key = (if @keyForRelationship then @keyForRelationship(key, "belongsTo") else key)
    if Ember.isNone(belongsTo)
      json[key] = belongsTo
    else
      return json[key.replace("_id", "") + "_attributes"] = record.get(relationship.key).serialize() if nested
      json[key] = Ember.get(belongsTo, "id")
    @serializePolymorphicType record, json, relationship  if relationship.options.polymorphic