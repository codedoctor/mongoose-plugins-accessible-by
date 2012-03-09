(function() {
  var AccessibleByType, ActorType, MediaLinkType, defaultIsPublicType, mongoose, _;

  mongoose = require("mongoose");

  _ = require('underscore');

  require('pkginfo')(module, 'version');

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

  /*
  The plugin.
  Options supported:
    defaultIsPublic - When set to true adds a default value that makes the associated object publicly readable.
    defaultPublicReadRole - The role that signifies read permission, used in default value generation. Defaults to "read"
  */

  exports.accessibleBy = function(schema, options) {
    if (options == null) options = {};
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
