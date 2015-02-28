# Indexed Store

Thin abstraction around a collection of JS objects that supports adding, retrieving, removing and updating items using multiple indices.

See: `test/test_store.coffee` for example usage

```coffeescript

{ Store, Key } = require 'indexed-store'

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

store = new Store(collection, 'id', new Key('type', false), 'color', new Key('unit', false, (o) -> o.unit.id))

equal store.getById(1), collection[0]
equal store.getByPk(1), collection[0]
sameMembers store.getByType('apple'), [collection[0], collection[3]]
# strawberry override unique red entry
equal store.getByColor('red'), collection[2]
sameMembers store.getByUnit(1), [collection[0], collection[3]]

o =
  id: 5
  type: 'pineapple'
  color: 'yellow'
  unit:
    id: 1

store.add o

sameMembers store.getAll(), collection.concat(o)
equal store.getById(5), o
equal store.getByPk(5), o
sameMembers store.getByType('pineapple'), [o]
# pineapple overrode unique yellow entry
equal store.getByColor('yellow'), o
sameMembers store.getByUnit(1), [collection[0], collection[3], o]

store.remove collection[0]

sameMembers store.getAll(), collection[1..]

isUndefined store.getById(1)
isUndefined store.getByPk(1)
sameMembers store.getByType('apple'), [collection[3]]
# removed conflated unique key entry (defining such an entry is an integrity error)
sameMembers store.getByUnit(1), [collection[3]]

original = _.cloneDeep collection[1]

collection[1].type = 'strawberry'
collection[1].color = 'green'
collection[1].unit.id = 3

store.update original, collection[1]

sameMembers store.getAll(), collection

sameMembers store.getByType('banana'), []
sameMembers store.getByType('strawberry'), [collection[1], collection[2]]
isUndefined equal store.getByColor('yellow')
# updated green strawberry overrode green apple
equal store.getByColor('green'), collection[1]
# updated the unit id, no longer 2, no entries
sameMembers store.getByUnit(2), []
sameMembers store.getByUnit(3), [collection[1], collection[2]]
```
