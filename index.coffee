_ = require 'lodash'


class Key
  constructor: (@name, @unique, @derive = @name) ->
    if _.isString @derive
      @derive = _.property(@derive)


class Index
  @toField: (name) -> "_by_#{name}"

  constructor: (@key) ->
    @field = Index.toField @key.name

  registerOn: (obj) ->
    keyName = @key.name
    obj[@field] = this
    obj["getBy#{_.capitalize(keyName)}"] = @get.bind(this)


class UniqueIndex extends Index
  reindex: (collection) ->
    @val = _.indexBy collection, @key.derive

  get: (k) -> @val[k]

  add: (object, k = @key.derive(object)) ->
    @val[k] = object
    k

  # returns generated key, which is required by downstream multivalued indices
  remove: (object, k = @key.derive(object)) ->
    delete @val[k]
    k

  # returns generated key, which is required by downstream multivalued indices
  update: (existing, object) ->
    k = @key.derive(object)
    @remove existing
    @add object, k


class PrimaryIndex extends UniqueIndex
  constructor: (key) ->
    throw TypeError("Primary key must be unique") unless key.unique
    super

  add: (object, k = @key.derive(object)) ->
    throw new TypeError("Object must include primary key") unless k?
    throw new TypeError("Object with primary key already in store") if @val[k]?
    super

  remove: (object, k = @key.derive(object)) ->
    throw new TypeError("Object must include primary key") unless k?
    existing = @val[k]
    throw new TypeError("Object not in store") unless existing?
    # results in pk being returned
    super


class MultiValuedIndex extends Index
  constructor: (key, @pk) ->
    super

  reindex: (collection) ->
    @val = _.groupBy collection, @key.derive

  get: (k) -> @val[k] ?= []

  add: (object, k = @key.derive(object)) ->
    (@val[k] ?= []).push object

  remove: (object, k = @key.derive(object), pk) ->
    entry = @val[k] ? []
    pkDerive = @pk.derive
    _.remove entry, (o) -> pk == pkDerive(o)

  update: (existing, object, pk) ->
    @remove existing, undefined, pk
    @add object, @key.derive(object)


class Collection
  constructor: (@collection, @pk) ->

  add: (object) ->
    @collection.push object

  remove: (object, _ignored, pk) ->
    pkDerive = @pk.derive
    _.remove @collection, (o) -> pk == pkDerive(o)

  update: (existing, object, pk, replace = false) ->
    if replace
      pkDerive = @pk.derive
      _.remove @collection, (o) -> pk == pkDerive(o)
      @collection.push object

  reindex: ->


class Store
  constructor: (@collection, keys...) ->
    throw new TypeError("Primary key is required") unless keys.length > 0

    keys = _.map keys, (arg, index) ->
      if _.isString arg
        new Key(arg, true)
      else if _.isFunction arg
        new Key(index.toString(), false, arg)
      else
        arg

    # generate indices and accessors
    @primaryIndex = new PrimaryIndex(keys[0])
    @indices = for key, i in keys[1..]
      if key.unique
        new UniqueIndex(key)
      else
        new MultiValuedIndex(key, @primaryIndex.key)

    for index in [@primaryIndex].concat @indices
      index.registerOn this

    collection = new Collection(@collection, @primaryIndex.key)
    @indices.push collection

    @reindex()

  reindex: ->
    @primaryIndex.reindex @collection
    for index in @indices
      index.reindex @collection

  getAll: -> @collection

  getByPk: (key) ->
    @primaryIndex.val[key]

  getBy: (keyName, key) ->
    index = @[Index.toField(keyName)]
    throw new TypeError("Invalid key: #{keyName}") unless index?
    index.val[key]

  add: (object) ->
    @primaryIndex.add object
    for index in @indices
      index.add object

  remove: (object) ->
    k = @primaryIndex.remove object
    for index in @indices
      index.remove object, undefined, k

  update: (existing, object, replace = false) ->
    k = @primaryIndex.update existing, object
    for index in @indices
      index.update existing, object, k, replace

module.exports.Store = Store
module.exports.Key = Key
