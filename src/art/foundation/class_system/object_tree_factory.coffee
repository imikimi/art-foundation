StandardLib = require '../standard_lib'
{upperCamelCase, compactFlatten} = StandardLib

module.exports = class ObjectTreeFactory
  deepArgsProcessing = (array, children) ->
    for el in array when el
      if el.constructor == Array
        deepArgsProcessing el, children
      else children.push el
    null

  @createObjectTreeFactory: (nodeFactory) ->
    ->
      oneProps = null
      props = null
      children = []

      for el in arguments when el
        switch el.constructor
          when Object
            if oneProps
              props = {}
              props[k] = v for k, v of oneProps
              oneProps = null
            if props
              props[k] = v for k, v of el
            else
              oneProps = el

          when Array
            deepArgsProcessing el, children
          else children.push el

      props ||= oneProps || {}
      nodeFactory props, children

  ###
  IN:
    list: a string or abitrary structure of arrays, nulls and strings
      each string is split into tokens and each token is used as the nodeName to create a Tree-factory
    nodeFactory: ->
      IN:
        nodeName: node-type name
        props:    plain object mapping props to prop-values
        children: flat, compacted array of children nodes
      OUT:
        node
  ###
  @createObjectTreeFactories: (list, nodeFactory) =>
    out = {}
    for str in compactFlatten list
      for nodeName in str.match /[a-z0-9_]+/ig
        do (nodeName) =>
          out[upperCamelCase nodeName] = @createObjectTreeFactory (props, children) ->
            nodeFactory nodeName, props, children
    out
