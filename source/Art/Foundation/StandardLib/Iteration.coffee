{compactFlatten, deepArrayEach, isArrayOrArguments, mergeInto} = Neptune.NeptuneLib
{isPlainObject, isObject, isFunction, isPlainArray} = require './Types'

log = ->
  Neptune.Art.Foundation.log arguments...

module.exports = class Iteration
  returnValueWithBlock = (v) -> v
  injectDefaultWithBlock = (memo, v) -> v
  arrayIterableTest = (source) -> source?.length >= 0

  ###
  COMMON API:

  IN: (source, withBlock = injectDefaultWithBlock) ->
  IN: (source, options) ->
  IN: (source, into, withBlock = injectDefaultWithBlock) ->
  IN: (source, into, options) ->

  source:
    array-like (see arrayIterableTest)
      use indexes to iterate

    non-null

  options:
    with: withBlock
    when: whenBlock
    into: into

  OUT: into

  TODO:
    - support ES6 iterables and iterators
    - skip: N - skip the first N values
    - short: N - stop short N values
    - by: N -
        N>0: only stop at every Nth value
        N<0: iterate in reverse order, only stop at every abs(N)th value
  ###

  ###
  each differences from the common-api:

  1) into defaults to source
  ###
  @each: (source, a, b) -> invokeNormalizedIteration normalizedEach, source, a, b
  normalizedEach = (source, into, withBlock, options) ->

    into = source if into == undefined

    if options
      whenBlock = options.when

    if arrayIterableTest source
      if whenBlock then withBlock v, k, into for v, k in source when whenBlock v, k
      else              withBlock v, k, into for v, k in source
    else
      if whenBlock then withBlock v, k, into for k, v of source when whenBlock v, k
      else              withBlock v, k, into for k, v of source

    into

  ###
  eachWhile differences from the common-api:

  1) into defaults to source
  2) stops when withBlock returns false
  ###
  @eachWhile: (source, a, b) -> invokeNormalizedIteration normalizedEachWhile, source, a, b
  normalizedEachWhile = (source, into, withBlock, options) ->

    into = source if into == undefined

    if options
      whenBlock = options.when

    if arrayIterableTest source
      if whenBlock
        for v, k in source when whenBlock v, k
          break unless withBlock v, k, into
      else
        for v, k in source
          break unless withBlock v, k, into
    else
      if whenBlock
        for k, v of source when whenBlock v, k
          break unless withBlock v, k, into
      else
        for k, v of source
          break unless withBlock v, k, into

    into

  ###
  reduce differences from the common-api:

  1) The with-block has a different argument order. Into is passed first instead of last:
    with: (into, value, key) ->
    This allows you to drop-in functions that take two arguments and reduce them to one like:
      Math.max
      add = (a, b) -> a + b

    The default with-block still returns value (which is now the second argument).

  1) if into starts out undefined:
    for v = the first value (if whenBlock is present, the first value when whenBlock is true)
      into = v
      skip: withBlock

  2) when withBlock is executed, into is updated:
    into = withBlock()
  ###
  @reduce: (source, a, b) ->
    invokeNormalizedIteration normalizedInject, source, a, b

  normalizedInject = (source, into, withBlock, options) ->
    return into unless source?

    withBlock ||= injectDefaultWithBlock

    normalizedEach source,
      undefined,
      if intoSet = into != undefined
            (v, k)-> into = withBlock into, v, k
      else  (v, k)-> into = if intoSet then withBlock into, v, k else intoSet = true; v
      options

    into

  ###
  object differences from the common-api:

  1) into defaults to a new object ({}) (if into == undefined)

  2) when withBlock is executed, into is updated:
    if source is array-like:
      into[v] = withBlock()
    else
      into[k] = withBlock()
  ###
  @object: (source, a, b) ->
    invokeNormalizedIteration normalizedObject, source, a, b

  normalizedObject = (source, into, withBlock, options) ->

    withBlock ||= returnValueWithBlock

    normalizedEach source,
      into = if into != undefined then into else {}
      if arrayIterableTest source
            (v, k) -> into[v] = withBlock v, k, into
      else  (v, k) -> into[k] = withBlock v, k, into
      options

  ###
  array differences from the common-api:

  1) into defaults to a new array ([]) (if into == undefined)

  2) when withBlock is executed, into is updated:
    into.push withBlock()
  ###
  @array: (source, a, b) ->
    invokeNormalizedIteration normalizedArray, source, a, b

  normalizedArray = (source, into, withBlock, options) ->

    withBlock ||= returnValueWithBlock

    normalizedEach source,
      into = if into != undefined then into else []
      (v, k) -> into.push withBlock v, k, into
      options

  ##########################
  # find
  ##########################
  ###
  differs from common api:

  1) returns the last value returned by withBlock or undefined if withBlock was never executed
  2) stops if
    a) whenBlock?:  and it returned true (stops after withBlock is evaluated)
    b) !whenBlock?: withBlock returns a truish value
  ###
  @find: (source, a, b) -> invokeNormalizedIteration normalizedFind, source, a, b
  normalizedFind = (source, into, withBlock, options) ->

    withBlock ||= returnValueWithBlock

    normalizedEachWhile source,
      into = undefined
      if options.whenBlock then (v, k) -> into = withBlock v, k; false
      else                      (v, k) -> !(into = withBlock v, k)
      options

    into

  #####################
  # PRIVATE
  #####################
  invokeNormalizedIteration = (iteration, source, a, b) ->
    options = if b
      into = a
      b
    else
      a

    if isFunction options
      withBlock = options
    else if isPlainObject options
      into = if options.into?
        options.into

      withBlock = options.with

    iteration source, into, withBlock, options