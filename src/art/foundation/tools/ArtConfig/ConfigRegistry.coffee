{
  defineModule
  log
  Promise
  inspect
  formattedInspect
  merge
  deepMerge
  mergeInto
  parseQuery
  pushIfNotPresent
  isPlainObject
  isString
  upperCamelCase
  expandPathedProperties
} = require '../../standard_lib'
{BaseObject} = require '../../class_system'

defineModule module, class ConfigRegistry extends BaseObject

  @artConfigName: defaultArtConfigName = "Development"
  @artConfig: {}

  @configurables: []
  @configs: {}

  @registerConfig: (name, config) =>
    throw new Error "config must be a plain object" unless isPlainObject config
    @configs[name] = config

  @registerConfigurable: (configurable) => pushIfNotPresent @configurables, configurable

  ###
  IN: configureOptions:
    artConfigName: string
      can be passed in:
        as an argument
        via process.env
        via the browser query string

      default: "Development"

      EFFECT:
        @artConfigName =
          externalEnvironment.artConfigName ||
          artConfigName

    artConfig: JSON string OR plain object structure
      can be passed in:
        as an argument
        via process.env
        via the browser query string

      default: {}

      EFFECT:
        mergeInto @artConfig, deepMerge
          @configs[artConfigName]
          global.artConfig
          artConfig
          externalEnvironment.artConfig

    IF artConfig IS NOT SET:
      artConfig is set to a clone of configureOptions with artConfigName removed.

  EFFECTS:
    callback @artConfig for callback in @configurables

  Note the priority order of artConfig sources:

  Priority:
    #1. externalEnvironment.artConfig
    #2. the artConfig passed into configure


  EXAMPLES:
    # artConfig = verbose: true
    ConfigRegistry.configure
      verbose: true

    # artConfig = verbose: true
    # artConfigName = "Production"
    ConfigRegistry.configure
      artConfigName: "Production"
      verbose: true

    # artConfig = verbose: true
    # artConfigName = "Production"
    ConfigRegistry.configure
      artConfigName: "Production"
      artConfig: verbose: true

  TEST INPUTS: the second and third inputs are env and
    queryString, and are only there as mocks for testing.
  ###
  @configure: (configureOptions...) =>
    {artConfigName: artConfigNameArgument, artConfig: artConfigArgument, __testEnv, __testQueryString} = @configureOptions = deepMerge configureOptions...

    unless artConfigArgument
      artConfigArgument = merge @configureOptions
      delete artConfigArgument.artConfigName

    artConfigGlobal = global.artConfig

    externalEnvironment = @getExternalEnvironment __testEnv, __testQueryString

    @artConfigName = externalEnvironment.artConfigName || artConfigNameArgument || global.artConfigName
    @artConfigName = @normalizeArtConfigName @artConfigName

    throw new Error "no config registered with name: #{@artConfigName}" if @artConfigName && !@configs[@artConfigName]

    @artConfigName ||= defaultArtConfigName

    delete @artConfig[k] for k, v of @artConfig

    for conf in [
        @configs[@artConfigName]
        artConfigGlobal
        artConfigArgument
        externalEnvironment.artConfig
      ]
      expandPathedProperties conf, @artConfig

    log ConfigRegistry: {@artConfigName, @artConfig}

    if @artConfig.verbose
      log ConfigRegistry:
        Verbose:
          registered:
            configs: Object.keys @configs
            configurables: (c.namespacePath for c in @configurables)
          artConfigName: firstTrue:
            "externalEnvironment.artConfigName": externalEnvironment.artConfigName
            artConfigNameArgument: artConfigNameArgument
            default: defaultArtConfigName

          artConfig: merge:
            "ConfigRegistry.configs.#{@artConfigName}": @configs[@artConfigName]
            artConfigGlobal:      artConfigGlobal
            artConfigArgument:    artConfigArgument
            artConfigFromExternalEnvironment:  externalEnvironment.artConfig

    @_executeCallbacks()

  @reload: => @configure @configureOptions

  ###############################
  # HELPERS
  ###############################
  # arguments are there for testing purposes
  @getExternalEnvironment: (env = global.process?.env, queryString = global.location?.search)->
    {artConfig, artConfigName} = externalEnvironment = env || parseQuery(queryString) || {}

    artConfig = if isPlainObject artConfig
      artConfig
    else if isString artConfig
      try
        JSON.parse artConfig
      catch e
        log.error """

          Invalid 'artConfig' from externalEnvironment. Must be valid JSON.

          #{formattedInspect externalEnvironment: externalEnvironment}

          error: #{e}

          """
        null

    {artConfig, artConfigName}

  ###
  normalized:
    map standard aliases (dev and prod)
    upperCamelCase
  ###
  @normalizeArtConfigName: (artConfigName)->
    switch artConfigName
      when "dev" then "Development"
      when "prod" then "Production"
      else artConfigName && upperCamelCase artConfigName

  ###############################
  # PRIVATE
  ###############################
  @_executeCallbacks: ->
    configurable.configure @artConfig for configurable in @configurables
