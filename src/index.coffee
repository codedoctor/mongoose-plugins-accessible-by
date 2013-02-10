mongoose = require("mongoose")
_ = require 'underscore'

require('pkginfo')(module,'version')

# Schemas used from activitystrea.ms
MediaLinkType = 
  height: Number
  width: Number
  url: String
        
ActorType =
  actorId:
    type: String
    required : true
  displayName:
    type: String
    match: /.{0,100}/
  image :
    type: MediaLinkType
  objectType : 
    type: "string"
    default: "person"

AccessibleByType = # new mongoose.Schema
  actor : 
    type : ActorType
    required: true
    match: /.{1,200}/
  roles:  
    type : [String]
    default: () -> ["read"]

# Creates a default entry, if necessary
defaultIsPublicType = (options) ->
  [
    actor : 
      actorId : options.publicActorId
      objectType : "public"
    roles : [options.defaultPublicReadRole]
  ]
  
_findAccessibleTypeForActorId = (model,actorId) ->
  _.find model.accessibleBy || [], (x) -> x.actor && x.actor.actorId is actorId


_findOrCreateAccessibleTypeForActor = (model,actor) ->
  #console.log "LOOKING FOR AT"
  at = _.find model.accessibleBy || [], (x) -> x.actor && x.actor.actorId is actor.actorId
  unless at
    at = 
      actor : actor
      roles : []
    model.accessibleBy.push at
    #model.markModified 'accessibleBy'
    #console.log "CREATED NEW AT"
  at
  
###
Converts an object, or null into an array. If it is already an array,
uniques will be removed and the array will be returned.
###
_arrayify = (obj) ->
  return [] unless obj
  return _.uniq(obj) if _.isArray obj
  [obj]
  
# Todo: Extend this so that we return the actorId if it is an actor object, not an id
_ensureActorId = (actorOrActorId,options) ->
  return actorOrActorId if _.isString actorOrActorId
  actorOrActorId.actorId
   
_ensureActor = (actorOrActorId,options) ->
  return actorOrActorId if actorOrActorId.actorId
  res = 
    actorId : actorOrActorId
    objectType : 'person'
    displayName : ""
  res
###
The plugin.
Options supported:
  defaultIsPublic - When set to true adds a default value that makes the associated object publicly readable.
  defaultPublicReadRole - The role that signifies read permission, used in default value generation. Defaults to "read"
###
exports.accessibleBy = (schema, options = {}) ->
  
  _.defaults options,
    defaultIsPublic : false
    defaultPublicReadRole : "read"
    publicActorId : "*"
  
  schema.add
    accessibleBy: 
      type : [AccessibleByType]
      default : () -> if options.defaultIsPublic then defaultIsPublicType(options) else []

  ###
  Method that determines if an actor specified with it's id has access to 
  the owning resource for the given role.
  ###
  schema.methods.canActorAccess = (actorOrActorId,role) ->
    #console.log "RRR: #{JSON.stringify(@)}"
    # Add is owner override here
    actorId = _ensureActorId(actorOrActorId,options)
    #console.log "ActorId: #{JSON.stringify(actorId)}"
    accessibleType = _findAccessibleTypeForActorId @,actorId
    #console.log "FOUND: #{JSON.stringify(accessibleType)}"
    !!accessibleType && _.include( accessibleType.roles,role)

  schema.methods.canPublicAccess =  (role)->
    @canActorAccess options.publicActorId,role

  ###
  Method that determines if the public has read access to this resource.
  ###
  schema.methods.canPublicRead =  ->
    @canActorAccess options.publicActorId,options.defaultPublicReadRole


  schema.methods.grantAccess = (actorOrActorId, roleOrRoles)  ->
    #console.log "-----------------------------------"

    actor =  _ensureActor(actorOrActorId)
    accessibleType = _findOrCreateAccessibleTypeForActor @,actor
    
    roleOrRoles = _arrayify(roleOrRoles)
    
    #console.log "SOURCE - TYPE: #{JSON.stringify(@)}"
    #console.log "ACCESSIBLE TYPE: #{JSON.stringify(accessibleType)}"
    #console.log "ROLES TO ADD: #{JSON.stringify(roleOrRoles)}"
    #console.log "EXISTING ROLES: #{JSON.stringify(accessibleType.roles)}"

    accessibleType.roles = _.union accessibleType.roles,roleOrRoles
    #console.log "NEW ROLES: #{JSON.stringify(accessibleType.roles)}"
    #console.log "SOURCE - SELF: #{JSON.stringify(@)}"

    @markModified "accessibleBy"
    @

  schema.methods.revokeAccess = (actorOrActorId, optionalRoleOrRoles = null)  ->
    actorId =  _ensureActorId(actorOrActorId)
    accessibleType = _findAccessibleTypeForActorId @,actorId
    if accessibleType
      optionalRoleOrRoles = _arrayify(optionalRoleOrRoles)
      if optionalRoleOrRoles.length > 0
        accessibleType.roles = _.difference accessibleType.roles,optionalRoleOrRoles
        if accessibleType.roles.length == 0
          @accessibleBy = _.without @accessibleBy,accessibleType
      else
        @accessibleBy = _.without @accessibleBy,accessibleType
        
      
      @markModified "accessibleBy"
    @

  schema.methods.replaceAccess = (actorOrActorId, optionalRoleOrRoles = null)  ->
    optionalRoleOrRoles = _arrayify(optionalRoleOrRoles)
    if optionalRoleOrRoles.length == 0
      actorId =  _ensureActorId(actorOrActorId)
      accessibleType = _findAccessibleTypeForActorId @,actorId
      if accessibleType
        @accessibleBy = _.without @accessibleBy,accessibleType 
        @markModified "accessibleBy"  
    else
      actor =  _ensureActor(actorOrActorId)
      accessibleType = _findOrCreateAccessibleTypeForActor @,actor
      accessibleType.roles = optionalRoleOrRoles
      @markModified "accessibleBy"  
    @

  ###
  Grants the public access to the resource. Grant always adds, it never replaces.
  Three possible invokations:
  resource.grantPublicAccess()
  resource.grantPublicAccess("somerole")
  resource.grantPublicAccess(["somerole","otherrole"])
  ###
  schema.methods.grantPublicAccess = (roleOrRoles)  ->
    @grantAccess options.publicActorId,roleOrRoles

  schema.methods.grantPublicReadOnlyAccess = ()  ->
    @grantAccess options.publicActorId,[options.defaultPublicReadRole]
  
  schema.methods.revokePublicAccess = (roleOrRoles = null)  ->
    @revokeAccess options.publicActorId,roleOrRoles

  schema.methods.replacePublicAccess = (roleOrRoles = null)  ->
    @replaceAccess options.publicActorId,roleOrRoles

      