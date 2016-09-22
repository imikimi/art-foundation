Foundation = Neptune.Art.Foundation
{log, inspectLean, inspect, isPlainArray, timeout} = Foundation
if self.document
  testLog = (args...) ->
    info = if args.length == 1
      if isPlainArray args[0]
        inspect args[0]
      else
        inspectLean args[0]
    else
      inspectLean args
    test "log #{info}", ->
      log args...

  module.exports = suite:
    atoms: ->
      testLog "a string"
      testLog 123
      testLog null
      testLog undefined

    arrays: ->
      testLog []
      testLog ["hello", "world"]
      testLog [1]
      testLog [1,2,3]

    errors: ->
      test "log thrown Error", ->
        try
          throw new Error "fake-fail"
        catch e
          log e

    objects: ->
      testLog {}
      testLog {a:1}
      testLog {a:1,b:2,c:3}
      testLog undefinedValue: undefined

    colors: ->
      testLog "#ffff00"
      testLog colorLikeString: "#ffff00"

    images: ->
      image = document.createElement "img"
      image.src = "https://upload.wikimedia.org/wikipedia/en/2/24/Lenna.png"
      testLog image: image
      class Foo
        getInspectedObjects: -> @
        toImage: -> image

      testLog hasToImage: new Foo

    promises: ->
      testLog
        foo: Promise.resolve a:12, b:13
        bar: timeout(10).then -> 456
      testLog
        foo: Promise.reject(123)
        bar: Promise.resolve(456)
