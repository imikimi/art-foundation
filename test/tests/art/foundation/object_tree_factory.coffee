Foundation = require 'art-foundation'
{createObjectTreeFactories, wordsArray, lowerCamelCase, log, BaseObject, mergeInto, isPlainObject} = Foundation

testNamesString = "Alice Bill John SallyMae"
testNames = wordsArray testNamesString
testNamesLowerCamelCased = (lowerCamelCase name for name in testNames)

suite "Art.Foundation.ObjectTreeFactory.createObjectTreeFactories", ->
  test "createObjectTreeFactories testNamesString", ->
    keys = Object.keys createObjectTreeFactories testNamesString
    assert.eq keys, testNames

  test "createObjectTreeFactories testNames", ->
    keys = Object.keys createObjectTreeFactories testNames
    assert.eq keys, testNames

  test "createObjectTreeFactories testNamesLowerCamelCased", ->
    keys = Object.keys createObjectTreeFactories testNamesLowerCamelCased
    assert.eq keys, testNames

  test 'createObjectTreeFactories ["Alice", "Bill John", ["SallyMae"]]', ->
    keys = Object.keys createObjectTreeFactories ["Alice", "Bill John", ["SallyMae"]]
    assert.eq keys, testNames

class MyObject extends BaseObject
  constructor: (@name, @props, @children) ->

  @getter
    plainObjects: ->
      out = [@name]
      out.push @props if Object.keys(@props).length > 0
      if @children.length > 0
        for child in @children
          out.push child.plainObjects
      out

suite "Art.Foundation.ObjectTreeFactory.using factories", ->

  {Alice, Bill, John, SallyMae} = createObjectTreeFactories testNamesLowerCamelCased, (name, props, children) ->
    new MyObject name, props, children

  test "Alice()", ->
    assert.eq Alice().plainObjects, ["alice"]

  test "Alice age:12", ->
    assert.eq Alice(age: 12).plainObjects, ["alice", age: 12]

  test "Alice age:12, Bill(), gender:'female'", ->
    tree = Alice
      age: 12
      Bill()
      gender: 'female'

    assert.eq tree.plainObjects, ["alice", age: 12, gender: 'female', ["bill"]]

  test "Alice Bill()", ->
    assert.eq Alice(Bill()).plainObjects, ["alice", ["bill"]]

  test "Alice Bill(), SallyMae()", ->
    assert.eq Alice(Bill(), SallyMae()).plainObjects, ["alice", ["bill"], ["sallyMae"]]

  test "Alice info:{a:123}, Bill(), info:{b:456}", ->
    tree = Alice info:{a:123}, Bill(), info:{b:456}
    assert.eq tree.plainObjects, ["alice", info:{b:456}, ["bill"]]

suite "Art.Foundation.ObjectTreeFactory.using factories with custom mergePropsInto", ->

  {Alice, Bill, John, SallyMae} = createObjectTreeFactories testNamesLowerCamelCased, (name, props, children) ->
    new MyObject name, props, children
  , ''
  , (into, source) ->
    for k, v of source
      into[k] = if isPlainObject v
        mergeInto into[k], v
      else
        v

  test "Alice info:{a:123}, Bill(), info:{b:456}", ->
    tree = Alice info:{a:123}, Bill(), info:{b:456}
    assert.eq tree.plainObjects, ["alice", info:{a:123, b:456}, ["bill"]]