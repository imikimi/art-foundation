# generated by Neptune Namespaces
# this file: src/art/foundation/browser/index.coffee

module.exports =
Browser        = require './namespace'
Browser.Cookie = require './cookie'
Browser.Dom    = require './dom'
Browser.File   = require './file'
Browser.Parse  = require './parse'
Browser.finishLoad(
  ["Cookie","Dom","File","Parse"]
  []
)