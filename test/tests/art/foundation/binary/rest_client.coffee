{assert} = require 'art-foundation/src/art/dev_tools/test/art_chai'
{Binary, log} = require 'art-foundation'
{binary} = Binary

suite "Art.Foundation.Binary.RestClient", ->

  test "get", ->
    Binary.RestClient.get "#{testAssetRoot}/array_buffer_rest_client_test/hello.txt"
    .then (string) ->
      assert.equal "hello in a file.", string

  test "getJson", ->
    Binary.RestClient.getJson "#{testAssetRoot}/array_buffer_rest_client_test/test.json"
    .then (json) ->
      assert.eq json, number: 123, object: {a: 1, b: 2, c: 3}, array: [1, 2, 3], true: true, false: false, string: "hi mom"

  test "getJson invalid.json", (done) ->
    Binary.RestClient.getJson "#{testAssetRoot}/array_buffer_rest_client_test/invalid.json"
    .then (json) ->
      assert.fail "should not get here since json is invalid", json
    , (error) ->
      log invalidJson:error
      self.invalidJson = error
      done()

  test "getArrayBuffer", ->
    Binary.RestClient.getArrayBuffer "#{testAssetRoot}/array_buffer_rest_client_test/hello.txt"
    .then (arrayBuffer) ->
      assert.equal "hello in a file.", binary(arrayBuffer).toString()

  test "onprogress", ->
    lastProgress =
    Binary.RestClient.get "#{testAssetRoot}/array_buffer_rest_client_test/hello.txt",
      onProgress: (progress) -> #onprogress
        lastProgress = progress
    .then (string) ->
      assert.equal "hello in a file.", string.toString()
      {event, progress} = lastProgress
      assert.equal progress, 1
      assert.equal event.loaded, event.total

  test "onerror", (done)->
    Binary.RestClient.get "#{testAssetRoot}/array_buffer_rest_client_test/doesnotexist.txt"
    .then (string) ->
      assert.equal "hello in a file.", string.toString()
    , (error) ->
      done()

