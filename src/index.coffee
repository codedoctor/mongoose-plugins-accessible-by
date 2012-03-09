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

AccessibleByType =
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
  at = _.find model.accessibleBy || [], (x) -> x.actor && x.actor.actorId is actor.actorId
  unless at
    at = 
      actor : actor
      roles : []
    model.accessibleBy.push at
  at
  

_arrayify = (obj) ->
  return [] unless obj
  return obj if _.isArray obj
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
    creator :
      fieldName : "createdBy"
      idFieldName: "actorId"
      hasFullAccess : true
  
  schema.add
    accessibleBy: 
      type : [AccessibleByType]
      default : () -> if options.defaultIsPublic then defaultIsPublicType(options) else []

  ###
  Method that determines if an actor specified with it's id has access to 
  the owning resource for the given role.
  ###
  schema.methods.canActorAccess = (actorId,role) ->
    # Add is owner override here
    actorId = _ensureActorId(actorId,options)
    accessibleType = _findAccessibleTypeForActorId @,actorId
    !!accessibleType && _.include( accessibleType.roles,role)

  schema.methods.canPublicAccess =  (role)->
    @canActorAccess options.publicActorId,role

  ###
  Method that determines if the public has read access to this resource.
  ###
  schema.methods.canPublicRead =  ->
    @canActorAccess options.publicActorId,options.defaultPublicReadRole


  schema.methods.grantAccess = (actorOrActorId, roleOrRoles)  ->
    actorOrActorId = _ensureActor(actorOrActorId)
    accessibleType = _findOrCreateAccessibleTypeForActor @,actorOrActorId
    
    roleOrRoles = _arrayify(roleOrRoles)
    
    _.each roleOrRoles, (role) ->
      accessibleType.roles.push(role) unless _.include(accessibleType.roles,role)
      
    @markModified "accessibleBy"
    return true

  schema.methods.revokeAccess = (actorId, optionalRoles = null)  ->
    return true

  schema.methods.replaceAccess = (actorId, optionalRoles = null)  ->
    return true

  ###
  Grants the public access to the resource. Grant always adds, it never replaces.
  Three possible invokations:
  resource.grantPublicAccess()
  resource.grantPublicAccess("somerole")
  resource.grantPublicAccess(["somerole","otherrole"])
  ###
  schema.methods.grantPublicAccess = (roles)  ->
    @grantAccess options.publicActorId,roles

  schema.methods.grantPublicReadOnlyAccess = ()  ->
    @grantAccess options.publicActorId,[options.defaultPublicReadRole]
  
  schema.methods.revokePublicAccess = (roles = null)  ->
    @revokeAccess options.publicActorId,roles

  schema.methods.replacePublicAccess = (roles = null)  ->
    @replaceAccess options.publicActorId,roles

      