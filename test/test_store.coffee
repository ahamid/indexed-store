_ = require 'lodash'
{ Store, Key } = require '../index'

collection = [
  id: 1
  type: 'apple'
  color: 'red'
  unit:
    id: 1
,
  id: 2
  type: 'banana'
  color: 'yellow'
  unit:
    id: 2
,
  id: 3
  type: 'strawberry'
  color: 'red'
  unit:
    id: 3
,
  id: 4
  type: 'apple'
  color: 'green'
  unit:
    id: 1
]

suite 'Store', ->
  setup ->
    @collection = _.cloneDeep(collection)
    @store = new Store(_.clone(@collection), 'id', new Key('type', false), 'color', new Key('unit', false, (o) -> o.unit.id))

  test 'generates accessors', ->
    isFunction @store.getById
    isFunction @store.getByPk
    isFunction @store.getByType
    isFunction @store.getByColor
    isFunction @store.getByUnit

  test 'get by primary key name', ->
    equal @store.getById(1), @collection[0]
    equal @store.getById(2), @collection[1]
    equal @store.getById(3), @collection[2]
    equal @store.getById(4), @collection[3]
    isUndefined @store.getById(5)

  test '#getByPk', ->
    equal @store.getByPk(1), @collection[0]
    equal @store.getByPk(2), @collection[1]
    equal @store.getByPk(3), @collection[2]
    equal @store.getByPk(4), @collection[3]
    isUndefined @store.getByPk(5)

  test 'get by non-unique property key', ->
    sameMembers @store.getByType('apple'), [@collection[0], @collection[3]]
    sameMembers @store.getByType('banana'), [@collection[1]]
    sameMembers @store.getByType('strawberry'), [@collection[2]]
    sameMembers @store.getByType('invalid'), []

  test 'get by unique property key', ->
    # strawberry is saved after apple so overwrites unique key value
    equal @store.getByColor('red'), @collection[2]
    equal @store.getByColor('yellow'), @collection[1]
    equal @store.getByColor('green'), @collection[3]
    isUndefined @store.getByColor('invalid')

  test 'get by custom key function', ->
    sameMembers @store.getByUnit(1), [@collection[0], @collection[3]]
    sameMembers @store.getByUnit(2), [@collection[1]]
    sameMembers @store.getByUnit(3), [@collection[2]]
    sameMembers @store.getByUnit(4), []

  test '#add', ->
    o =
      id: 5
      type: 'pineapple'
      color: 'yellow'
      unit:
        id: 1

    @store.add o

    sameMembers @store.getAll(), @collection.concat(o)

    equal @store.getById(1), @collection[0]
    equal @store.getById(2), @collection[1]
    equal @store.getById(3), @collection[2]
    equal @store.getById(4), @collection[3]
    equal @store.getById(5), o
    isUndefined @store.getById(6)
    equal @store.getByPk(1), @collection[0]
    equal @store.getByPk(2), @collection[1]
    equal @store.getByPk(3), @collection[2]
    equal @store.getByPk(4), @collection[3]
    equal @store.getByPk(5), o
    isUndefined @store.getByPk(6)
    sameMembers @store.getByType('apple'), [@collection[0], @collection[3]]
    sameMembers @store.getByType('banana'), [@collection[1]]
    sameMembers @store.getByType('strawberry'), [@collection[2]]
    sameMembers @store.getByType('pineapple'), [o]
    sameMembers @store.getByType('invalid'), []
    equal @store.getByColor('red'), @collection[2]
    # pineapple overrode unique index val
    equal @store.getByColor('yellow'), o
    equal @store.getByColor('green'), @collection[3]
    equal @store.getByColor('invalid'), null
    sameMembers @store.getByUnit(1), [@collection[0], @collection[3], o]
    sameMembers @store.getByUnit(2), [@collection[1]]
    sameMembers @store.getByUnit(3), [@collection[2]]
    sameMembers @store.getByUnit(4), []


  test '#remove', ->
    @store.remove @collection[0]

    sameMembers @store.getAll(), @collection[1..]

    isUndefined @store.getById(1)
    equal @store.getById(2), @collection[1]
    equal @store.getById(3), @collection[2]
    equal @store.getById(4), @collection[3]
    isUndefined @store.getById(5)
    isUndefined @store.getByPk(1)
    equal @store.getByPk(2), @collection[1]
    equal @store.getByPk(3), @collection[2]
    equal @store.getByPk(4), @collection[3]
    isUndefined @store.getByPk(5)
    sameMembers @store.getByType('apple'), [@collection[3]]
    sameMembers @store.getByType('banana'), [@collection[1]]
    sameMembers @store.getByType('strawberry'), [@collection[2]]
    sameMembers @store.getByType('invalid'), []
    # removed what was defined as a unique key even though another entry had that key
    # defining such a key is an integrity error
    isUndefined @store.getByColor('red')
    equal @store.getByColor('yellow'), @collection[1]
    equal @store.getByColor('green'), @collection[3]
    equal @store.getByColor('invalid'), null
    sameMembers @store.getByUnit(1), [@collection[3]]
    sameMembers @store.getByUnit(2), [@collection[1]]
    sameMembers @store.getByUnit(3), [@collection[2]]
    sameMembers @store.getByUnit(4), []


  test '#update', ->
    original = _.cloneDeep @collection[1]

    @collection[1].type = 'strawberry'
    @collection[1].color = 'green'
    @collection[1].unit.id = 3

    @store.update original, @collection[1]

    sameMembers @store.getAll(), @collection

    equal @store.getById(1), @collection[0]
    equal @store.getById(2), @collection[1]
    equal @store.getById(3), @collection[2]
    equal @store.getById(4), @collection[3]
    isUndefined @store.getById(5)
    equal @store.getByPk(1), @collection[0]
    equal @store.getByPk(2), @collection[1]
    equal @store.getByPk(3), @collection[2]
    equal @store.getByPk(4), @collection[3]
    isUndefined @store.getByPk(5)
    sameMembers @store.getByType('apple'), [@collection[0], @collection[3]]
    sameMembers @store.getByType('banana'), []
    sameMembers @store.getByType('strawberry'), [@collection[1], @collection[2]]
    sameMembers @store.getByType('invalid'), []
    equal @store.getByColor('red'), @collection[2]
    # pineapple overrode unique index val
    isUndefined equal @store.getByColor('yellow')
    # updated green strawberry overrode green apple
    equal @store.getByColor('green'), @collection[1]
    equal @store.getByColor('invalid'), null
    sameMembers @store.getByUnit(1), [@collection[0], @collection[3]]
    # updated the unit id, no longer 2, no entries
    sameMembers @store.getByUnit(2), []
    sameMembers @store.getByUnit(3), [@collection[1], @collection[2]]
    sameMembers @store.getByUnit(4), []