# promise-polyfill takes advantage of setImmediate for performance gains
# This polyfil promises good setImmediate performance: https://github.com/YuzuJS/setImmediate
Promise = require 'promise-polyfill'
{deepMap, deepEach, isFunction} = require './types'

###
ArtPromise extends ES6 Promises in the following ways:

- constructing a promise with no parameters is allowed
- promise.resolve and promise.reject are supported as
  alternative ways to resolve or reject a promise

If native promises are supported, they are used,
otherwise a polyfill is used.

TODO: ES6 says Promises are designed to be extensible:
  http://www.ecma-international.org/ecma-262/6.0/#sec-promise-objects

  But I had problems doing that. Maybe it's how CoffeeScript extends things?
###
module.exports = class ArtPromise #extends Promise
  @ES6Promise: Promise
  @all: Promise.all
  @race: Promise.race
  @reject: Promise.reject
  @resolve: Promise.resolve
  @then: (f) -> Promise.resolve().then f
  @isPromise: isPromise = (f) -> isFunction f?.then
  @testPromise: (promise) ->
    promise.then  (v) -> console.log "promise.resolve", v
    promise.catch (v) -> console.log "promise.reject", v
  @mapAll: (map) ->
    keys = Object.keys map
    Promise.all(map[key] for key in keys)
    .then (values) ->
      out = {}
      out[key] = values[i] for key, i in keys
      out

  @containsPromises: (plainStructure) ->
    containsPromises = false
    deepEach plainStructure, (v) -> containsPromises ||= isPromise v
    containsPromises

  noop = (a) -> a
  @deepAll: (plainStructure, resolvedResultPreprocessor = noop) ->
    promises = []

    deepEach plainStructure, (v) ->
      promises.push v if isPromise v

    Promise.all promises
    .then (resolved) ->
      i = 0
      deepMap plainStructure, (v) ->
        if isPromise v
          resolvedResultPreprocessor resolved[i++]
        else
          v

  ###
  Serializer makes it easy to ensure promise-returning functions are invoked in order, after each
  promise is resolved.

  USAGE:

    # EXAMPLE 1: Basic - not too different from normal Promise sequences
    serializer = new ArtPromise.Serializer
    serializer.then -> doA()

    # then execute sometime later, possbly asynchronously:
    serializer.then -> doB()

    # then execute sometime later, possbly asynchronously:
    serializer.then (doBResult) ->
      # doA and doB have completed and any returning promises resolved
      # the result of the last 'then' is passed in

    # EXAMPLE 2: apply the same async function serially to each element in list
    # - list's order is preserved
    # - each invocation waits for the previous one to complete
    serializer = new ArtPromise.Serializer
    list.forEach serializer.serialize f = (element) -> # do something with element, possibly returning a promise
    serializer.then (lastFResult) ->
      # do something after the last invocation of f completes
      # the result of the last invocation of 'f' is passed in

    # EXAMPLE 3: mix multiple serialized functions and manual @then invocations
    # - invocation order is perserved
    serializer = new ArtPromise.Serializer
    serializedA = serializer.serialize aFunction
    serializedB = serializer.serialize bFunction

    serializedB()
    serializer.then -> @cFunction()
    serializedB()
    serializedA()
    serializedB()

    serializer.then (lastBFunctionResult) ->
      # this is invoked AFTER:
      # evaluating, in order, waiting for any promises:
      #   bFunction, cFunction, bFunction, aFunction, bFunction
  ###
  class ArtPromise.Serializer
    constructor: -> @_lastPromise = ArtPromise.resolve()

    ###
    Returns a new function, serializedF, that acts just like 'f'
      - f is forced to be async:
        - if f doesn't return a promise, a promise wrapping f's result is returned
      - invoking serializedF queues f in this serializer instance's sequence via @then
    IN: any function with any signature
    OUT: (f's signature) -> promise.then (fResult) ->

    Example with Comparison:

      # all asyncActionReturningPromise(element)s get called immediately
      # and may complete randomly at some later event
      myArray.forEach (element) ->
        asyncActionReturningPromise element

      # VS

      # asyncActionReturningPromise(element) only gets called
      # after the previous call completes.
      # If a previous call failes, the remaining calls never happen.
      serializer = new Promise.Serializer
      myArray.forEach serializer.serialize (element) ->
        asyncActionReturningPromise element

      # bonus, you can do things when all the promises complete:
      serializer.then =>

      # or if anything fails
      serializer.catch =>

      # VS - shortcut

      # Just insert "Promise.serialize" before your forEach function to ensure serial invocations.
      # However, you don't get the full functionality of the previous example.
      myArray.forEach Promise.serialize (element) ->
        asyncActionReturningPromise element


    ###
    serialize: (f) ->
      =>
        args = arguments
        @then -> f args...

    # invoke f after the last serialized invocation's promises are resolved
    # OUT: promise.then (fResult) ->
    then: (f, rejected) -> @_lastPromise = @_lastPromise.then f, rejected

    catch: (f) -> @_lastPromise = @_lastPromise.catch f

    # ignore previous errors, always do f after previous successes or failures complete.
    always: (f) ->
      @_lastPromise = @_lastPromise
      .catch => null
      .then f

  ###
  OUT: serializedF = -> Promise.resolve f arguments...
    IN: any arguments
    EFFECT: f is invoked with arguments passed in AFTER the last invocation of serializedF completes.
    OUT: promise.then -> results from f

  NOTE: 'f' can return a promise, but it doesn't have to. If it does return a promise, the next
    'f' invocation will not start until and if the previous one's promise completes.

  USAGE:
    serializedF = Promise.serialize f = -> # do something, possibly returning a promise
    serializedF()
    serializedF()
    serializedF()
    .then (resultOfLastF)->
      # executed after f was executed and any returned promises resolved, 3 times, sequentially

  OR
    serializedF = Promise.serialize f = (element) -> # do something with element, possibly returning a promise
    Promise.all (serializedF item for item in list)
    .then (results) ->
      # f was excuted list.length times sequentially
      # results contains the result values from each execution, in order

  ###
  @serialize: (f) -> new ArtPromise.Serializer().serialize f

  constructor: (_function)->
    @resolve = @reject = null
    @_nativePromise = null
    @_nativePromise = new Promise (@resolve, @reject) =>
      _function? @resolve, @reject

  then: (a, b) -> @_nativePromise.then a, b
  catch: (a) -> @_nativePromise.catch a

self.Promise ||= ArtPromise
