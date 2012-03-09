(function() {
  var AccessibleByType, ActorType, BinaryParser, MediaLinkType, ObjectID, defaultIsPublicType, mongoose, _;

  mongoose = require("mongoose");

  ObjectID = mongoose.ObjectID;

  BinaryParser = mongoose.mongo.BinaryParser;

  _ = require('underscore');

  MediaLinkType = {
    height: Number,
    width: Number,
    url: String
  };

  ActorType = {
    actorId: {
      type: String,
      required: true
    },
    displayName: {
      type: String,
      match: /.{0,100}/
    },
    image: {
      type: MediaLinkType
    },
    objectType: {
      type: "string",
      "default": "person"
    }
  };

  AccessibleByType = {
    actor: {
      type: ActorType,
      required: true,
      match: /.{1,200}/
    },
    roles: {
      type: [String],
      "default": function() {
        return ["read"];
      }
    }
  };

  defaultIsPublicType = function(options) {
    return [
      {
        actor: {
          actorId: "*",
          objectType: "public"
        },
        roles: [options.defaultPublicReadRole]
      }
    ];
  };

  exports.accessibleBy = function(schema, options) {
    if (!options) options = {};
    _.defaults(options, {
      defaultIsPublic: false,
      defaultPublicReadRole: "read"
    });
    return schema.add({
      accessibleBy: {
        type: [AccessibleByType],
        "default": function() {
          if (options.defaultIsPublic) {
            return defaultIsPublicType(options);
          } else {
            return [];
          }
        }
      }
    });
  };

}).call(this);
