# generated by Neptune Namespaces v0.3.0
# file: art/dev_tools/dom_console/index.coffee

(module.exports = require './namespace')
.includeInNamespace(require './_dom_console')
.addModules
  Chart:      require './chart'
  Console:    require './console'
  ToolBar:    require './tool_bar'
require './pseudo_react'