mongoose = require("mongoose")
ObjectID = mongoose.ObjectID
BinaryParser = mongoose.mongo.BinaryParser
_ = require 'underscore'

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

defaultIsPublicType = (options) ->
  [
    actor : 
      actorId : "*"
      objectType : "public"
    roles : [options.defaultPublicReadRole]
  ]
    
exports.accessibleBy = (schema, options) ->
  options = {} unless options
  
  _.defaults options,
    defaultIsPublic : false
    defaultPublicReadRole : "read"
  
  schema.add
    accessibleBy: 
      type : [AccessibleByType]
      default : () -> if options.defaultIsPublic then defaultIsPublicType(options) else []

