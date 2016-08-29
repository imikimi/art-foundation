StandardLib = require '../standard_lib'

{
  merge, log, BaseObject, shallowClone
  isNumber, isString, isPlainObject, isPlainArray
  Promise
  isBoolean
  formattedInspect
  present
} = StandardLib

###
NOTES:

  validators are evaluated before preprocessors

  preprocessors should NOT throw validation-related errors

  TODO?: We could add postValidators to allow you to validate AFTER the preprocessor...

USAGE:
  new Validator validatorFieldsProps
    IN:
      validatorFieldsProps:
        plain object with zero or more field-validations defined:
          fieldName: validatorFieldProps

    validatorFieldProps:
      string or plainObject
      string: selects validatorFieldProps from one of the standard @fieldTypes (see below)
      plainObject: (all fields are optional)

        validate: (v) -> true/false
          whenever this field is included in an update OR create operation,
            validate() must return true
          NOTE: is evaluated BEFORE preprocess

        preprocess: (v1) -> v2
          whenever this field is included in an update OR create operation,
            after validation succeeds,
            value = preprocess value

        required: true/false
          when creating records, this field must be included

        requiredPresent: true/false
          when creating records, this field must be include and 'present' (see Art.Foundation.present)

        type:
          sepecify which of the standard Json data-types this field contains
          This is not used by Validator itself, but is available for clients to reflect on field-types.
          Must be one of the values in: @dataTypes
          default: 'string'

EXAMPLES:
  new

###

{BaseObject} = require '../class_system'

isId = (v) -> isString(v) && v.match ///^[-_a-z0-9]+$///i
isHexColor = (v) -> isString(v) && v.match /^#([a-f0-9]{3})|([a-f0-9]{6})/i

module.exports = class Validator extends BaseObject

  ###
  @dataTypes only includes the Standard Json types:
    except 'null':
      no field has the type of 'null'
      instead, it has some other type and can be 'null' unless it is 'required'
  ###
  @dataTypes: dataTypes =
    boolean:    validate: (a) -> isBoolean a
    number:     validate: (a) -> isNumber a
    string:     validate: (a) -> isString a
    object:     validate: (a) -> isPlainObject a
    array:      validate: (a) -> isPlainArray a

  booleanDataType = "boolean"
  numberDataType =  "number"
  stringDataType =  "string"
  objectDataType =  "object"
  arrayDataType =   "array"

  ###
  standard FieldType props:
    validate: (v) -> true/false
    preprocess: (v1) -> v2
    required: true/false
    type: one of @dataTypes, default: 'string'

  You can add your own, too, but they are ignored by this class.
  ###
  # fieldTypes are just easy, pre-defined Objects with the right properties:
  # Usage:
  #   This:           @fields webPage: @fieldTypes.id
  #   is the same as: @fields webPage: validate: (v) -> isId v
  #   and this:       @fields webPage: type: "id"
  @fieldTypes: fieldTypes =
    boolean:  type: booleanDataType
    number:   type: numberDataType
    string:   {}
    object:   type: objectDataType
    array:    type: arrayDataType

    count:    type: numberDataType

    id:
      required: true
      validate: (v) -> isId v

    date:
      validate:   (v) -> isString(v) || (v instanceof Date)
      preprocess: (v) -> if isString(v) then new Date v else v

    timestamp: # milliseconds since 1970; to get the current timestamp: Date.now()
      type: numberDataType
      validate:   (v) -> isNumber(v) || (v instanceof Date)
      preprocess: (v) -> if v instanceof Date then v - 0 else v

    color:
      validate: (v) -> isHexColor v

    email:
      validate: (v) -> isString(v) && v.trim().match emailRegexp
      preprocess: (v) -> v.trim().toLowerCase()

    url:
      validate: (v) -> isString(v) && v.match urlRegexp
      preprocess: (v) -> normalizeUrl v # downcase protocol and domain name

    trimmedString:
      validate: (v) ->
        log trimmedString:validate: v
        isString v
      preprocess: (v) -> v.trim()

  # apply defaults
  for k, v of fieldTypes
    v.type ||= stringDataType
    v.validate ||= dataTypes[v.type].validate

  @normalizeFieldType: normalizeFieldType = (ft) ->
    if isPlainObject ft
      if isString ft.required
        ft = merge ft,
          normalizeFieldType ft.required
          required: true
      if isString ft.requiredPresent
        ft = merge ft,
          normalizeFieldType ft.requiredPresent
          requiredPresent: true
      ft
    else if isString ft
      throw new Error "invalid named fieldType: #{string}" unless ft = fieldTypes[ft]
      ft
    else
      throw new Error "fieldType must be a string or plainObject: #{formattedInspect ft}"

  constructor: (fieldDeclarationMap) ->
    @_fieldProps = {}
    @addFields fieldDeclarationMap

  addFields: (fieldDeclarationMap) ->
    for field, fieldOptions of fieldDeclarationMap
      @_addField field, fieldOptions

  ###
  OUT:
    promise.then (validatedPreprocessedFields) ->
    .catch (validationFailureInfoObject) ->
  ###
  preCreate: (fields) -> Promise.resolve().then => @preCreateSync fields

  ###
  OUT:
    promise.then (validatedPreprocessedFields) ->
    .catch (validationFailureInfoObject) ->
  ###
  preUpdate: (fields) -> Promise.resolve().then => @preUpdateSync fields

  preCreateSync: (fields) ->
    if @requiredFieldsPresent(fields) && @presentFieldsValid fields
      @preprocessFields fields
    else
      throw
        invalidFields: @invalidFields fields
        missingFields: @missingFields fields

  preUpdateSync: (fields) ->
    if @presentFieldsValid fields
      @preprocessFields fields
    else
      throw
        invalidFields: @invalidFields fields

  ####################
  # VALIDATION CORE
  ####################
  presentFieldValid: (fields, fieldName) ->
    {validate} = @_fieldProps[fieldName]
    !validate || !(value = fields[fieldName])? || validate value

  requiredFieldPresent: (fields, fieldName) ->
    {required, requiredPresent} = @_fieldProps[fieldName]
    return false if required && !(fields[fieldName]? || fields[required]?)
    return false if requiredPresent && !present fields[fieldName]
    true

  presentFieldsValid: (fields) ->
    for fieldName, _ of @_fieldProps
      return false unless @presentFieldValid fields, fieldName
    true

  requiredFieldsPresent: (fields) ->
    for fieldName, _ of @_fieldProps
      return false unless @requiredFieldPresent fields, fieldName
    true

  ####################
  # PREPROCESS CORE
  ####################
  preprocessFields: (fields) ->
    processedFields = null
    for fieldName, {preprocess} of @_fieldProps when preprocess && (value = fields[fieldName])?
      if (v = preprocess oldV = fields[fieldName]) != oldV
        processedFields ||= shallowClone fields
        processedFields[fieldName] = v
    processedFields || fields

  ####################
  # VALIDATION INFO CORE
  ####################
  missingFields: (fields) -> name for name, _ of @_fieldProps when !@requiredFieldPresent fields, name
  invalidFields: (fields) -> name for name, _ of @_fieldProps when !@presentFieldValid fields, name


  ###################
  # PRIVATE
  ###################
  _addField: (field, options) ->
    options = normalizeFieldType options
    @_fieldProps[field] = merge null,
      fieldTypes[options.type]
      options
      if _instanceof = options.instanceof
        {validate} = options
        validate: (v) ->
          (v instanceof _instanceof) &&
          (!validate || validate v)
