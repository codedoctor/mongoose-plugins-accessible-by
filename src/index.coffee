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
      actorId : "*"
      objectType : "public"
    roles : [options.defaultPublicReadRole]
  ]
  

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
  
  schema.add
    accessibleBy: 
      type : [AccessibleByType]
      default : () -> if options.defaultIsPublic then defaultIsPublicType(options) else []

