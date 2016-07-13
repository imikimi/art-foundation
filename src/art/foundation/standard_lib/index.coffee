# generated by Neptune Namespaces v0.5
# file: art/foundation/standard_lib/index.coffee

module.exports = require './namespace'
.includeInNamespace require './_standard_lib'
.addModules
  ArrayCompactFlatten: require './array_compact_flatten'
  ArrayExtensions:     require './array_extensions'     
  AsyncExtensions:     require './async_extensions'     
  Eq:                  require './eq'                   
  Function:            require './function'             
  Hash:                require './hash'                 
  Math:                require './math'                 
  ObjectDiff:          require './object_diff'          
  ParseUrl:            require './parse_url'            
  Promise:             require './promise'              
  PromisedFileReader:  require './promised_file_reader' 
  Regexp:              require './regexp'               
  Ruby:                require './ruby'                 
  ShallowClone:        require './shallow_clone'        
  StringCase:          require './string_case'          
  String:              require './string'               
  Time:                require './time'                 
  Types:               require './types'                
  Unique:              require './unique'               