define [
  "../base_object"
  "../types"
  "../string"
  "../map"
  "../neptune_coffee"
  "./namespace"
], (BaseObject, Types, StringExtensions, Map, NeptuneCoffee, Inspect) ->
  {classPathName} = NeptuneCoffee
  {escapeJavascriptString} = StringExtensions
  {isString, isArray, isFunction, isObject, isClass, objectName, isBrowserObject} = Types

  class Inspector extends BaseObject
    @unquotablePropertyRegex: /^([0-9]+|[_a-zA-Z][_0-9a-zA-Z]*)$/

    # Note = we never want to use a custom inspection function for function objects (which may be classes)
    @customInspectable: (obj) => obj.inspect && !(typeof obj == "function")

    @parentString: (distance) =>
      switch distance
        when 0 then "parent"
        when 1 then "grandparent"
        when 2 then "great grandparent"
        else "great^#{distance-1} grandparent"


    constructor: (options = {})->
      @maxLength = options.maxLength || 1000
      @allowCustomInspectors = !options.noCustomInspectors
      @maxDepth = if options.maxDepth? then options.maxDepth else 10
      @outArray = []
      @length = 0
      @depth = 0
      @inspectingMap = new Map
      @done = false

    put: (s) ->
      return if @done
      @outArray.push if @length + s.length > @maxLength
        @done = true
        "..."
      else
        @length += s.length
        s
      s

    @getter
      result: -> @outArray.join ""

    maxDepthOutput: (obj) ->
      switch typeof obj
        when "string", "number", "boolean", "undefined" then @inspectInternal obj
        when "function"
          @put objectName obj
        when "object"
          @put if obj == null
            "null"
          else if isArray obj
            "[#{obj.length} elements]"
          else
            keys = Object.keys obj
            name = objectName obj
            if name == "Object"
              "{#{keys.length} keys}"
            else if keys.length > 0
              "{#{name} #{keys.length} keys}"
            else
              name

    inspectArray: (array) =>
      @put "["
      first = true
      for obj in array
        @put ", " unless first
        @inspect obj
        first = false
      @put "]"

    inspectObject: (obj) =>
      attributes = []
      keys = Object.keys obj
      name = objectName obj
      if isFunction(obj) and keys.length == 0
        @put name + "()"
      else if isBrowserObject obj
        @put "{#{name}}"
      else
        @put "{"
        @put "#{name} " unless obj.constructor == Object

        first = true
        for k in keys when k != "__uniqueId"
          @put ", " unless first
          v = obj[k]
          if Inspector.unquotablePropertyRegex.test k
            @put k
          else
            @inspect k
          @put ": "
          @inspect v
          first = false

        @put "}"

    inspectInternal: (obj) =>
      if !obj?                                                then @put "#{obj}"
      else if isString obj                                    then @put escapeJavascriptString obj
      else if isArray obj                                     then @inspectArray obj
      else if isClass(obj)                                    then @put objectName(obj)
      else if @allowCustomInspectors && Inspector.customInspectable obj then obj.inspect @
      else if isObject(obj) || isFunction(obj)                then @inspectObject obj
      else                                                         @put "#{obj}"

    inspect: (obj) =>
      return if @done

      if objDepth = @inspectingMap.get obj
        @put "<#{Inspector.parentString @depth - objDepth}>"
        return null

      if @depth >= @maxDepth
        @maxDepthOutput obj
      else
        @depth++
        @inspectingMap.set obj, @depth
        @inspectInternal obj
        @inspectingMap.delete obj
        @depth--

      null
