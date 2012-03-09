(function() {
  var AccessibleByType, ActorType, MediaLinkType, defaultIsPublicType, mongoose, _, _arrayify, _ensureActor, _ensureActorId, _findAccessibleTypeForActorId, _findOrCreateAccessibleTypeForActor;

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
          actorId: options.publicActorId,
          objectType: "public"
        },
        roles: [options.defaultPublicReadRole]
      }
    ];
  };

  _findAccessibleTypeForActorId = function(model, actorId) {
    return _.find(model.accessibleBy || [], function(x) {
      return x.actor && x.actor.actorId === actorId;
    });
  };

  _findOrCreateAccessibleTypeForActor = function(model, actor) {
    var at;
    at = _.find(model.accessibleBy || [], function(x) {
      return x.actor && x.actor.actorId === actor.actorId;
    });
    if (!at) {
      at = {
        actor: actor,
        roles: []
      };
      model.accessibleBy.push(at);
    }
    return at;
  };

  /*
  Converts an object, or null into an array. If it is already an array,
  uniques will be removed and the array will be returned.
  */

  _arrayify = function(obj) {
    if (!obj) return [];
    if (_.isArray(obj)) return _.uniq(obj);
    return [obj];
  };

  _ensureActorId = function(actorOrActorId, options) {
    if (_.isString(actorOrActorId)) return actorOrActorId;
    return actorOrActorId.actorId;
  };

  _ensureActor = function(actorOrActorId, options) {
    var res;
    if (actorOrActorId.actorId) return actorOrActorId;
    res = {
      actorId: actorOrActorId,
      objectType: 'person',
      displayName: ""
    };
    return res;
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
      defaultPublicReadRole: "read",
      publicActorId: "*",
      creator: {
        fieldName: "createdBy",
        idFieldName: "actorId",
        hasFullAccess: true
      }
    });
    schema.add({
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
    /*
      Method that determines if an actor specified with it's id has access to 
      the owning resource for the given role.
    */
    schema.methods.canActorAccess = function(actorId, role) {
      var accessibleType;
      actorId = _ensureActorId(actorId, options);
      accessibleType = _findAccessibleTypeForActorId(this, actorId);
      return !!accessibleType && _.include(accessibleType.roles, role);
    };
    schema.methods.canPublicAccess = function(role) {
      return this.canActorAccess(options.publicActorId, role);
    };
    /*
      Method that determines if the public has read access to this resource.
    */
    schema.methods.canPublicRead = function() {
      return this.canActorAccess(options.publicActorId, options.defaultPublicReadRole);
    };
    schema.methods.grantAccess = function(actorOrActorId, roleOrRoles) {
      var accessibleType, actor;
      actor = _ensureActor(actorOrActorId);
      accessibleType = _findOrCreateAccessibleTypeForActor(this, actor);
      roleOrRoles = _arrayify(roleOrRoles);
      _.each(roleOrRoles, function(role) {
        if (!_.include(accessibleType.roles, role)) {
          return accessibleType.roles.push(role);
        }
      });
      this.markModified("accessibleBy");
      return this;
    };
    schema.methods.revokeAccess = function(actorOrActorId, optionalRoleOrRoles) {
      var accessibleType, actorId;
      if (optionalRoleOrRoles == null) optionalRoleOrRoles = null;
      actorId = _ensureActorId(actorOrActorId);
      accessibleType = _findAccessibleTypeForActorId(this, actorId);
      if (accessibleType) {
        optionalRoleOrRoles = _arrayify(optionalRoleOrRoles);
        if (optionalRoleOrRoles.length > 0) {
          accessibleType.roles = _.difference(accessibleType.roles, optionalRoleOrRoles);
          if (accessibleType.roles.length === 0) {
            this.accessibleBy = _.without(this.accessibleBy, accessibleType);
          }
        } else {
          this.accessibleBy = _.without(this.accessibleBy, accessibleType);
        }
        this.markModified("accessibleBy");
      }
      return this;
    };
    schema.methods.replaceAccess = function(actorOrActorId, optionalRoleOrRoles) {
      var accessibleType, actor, actorId;
      if (optionalRoleOrRoles == null) optionalRoleOrRoles = null;
      optionalRoleOrRoles = _arrayify(optionalRoleOrRoles);
      if (optionalRoleOrRoles.length === 0) {
        actorId = _ensureActorId(actorOrActorId);
        accessibleType = _findAccessibleTypeForActorId(this, actorId);
        if (accessibleType) {
          this.accessibleBy = _.without(this.accessibleBy, accessibleType);
          this.markModified("accessibleBy");
        }
      } else {
        actor = _ensureActor(actorOrActorId);
        accessibleType = _findOrCreateAccessibleTypeForActor(this, actor);
        accessibleType.roles = optionalRoleOrRoles;
        this.markModified("accessibleBy");
      }
      return this;
    };
    /*
      Grants the public access to the resource. Grant always adds, it never replaces.
      Three possible invokations:
      resource.grantPublicAccess()
      resource.grantPublicAccess("somerole")
      resource.grantPublicAccess(["somerole","otherrole"])
    */
    schema.methods.grantPublicAccess = function(roles) {
      return this.grantAccess(options.publicActorId, roles);
    };
    schema.methods.grantPublicReadOnlyAccess = function() {
      return this.grantAccess(options.publicActorId, [options.defaultPublicReadRole]);
    };
    schema.methods.revokePublicAccess = function(roles) {
      if (roles == null) roles = null;
      return this.revokeAccess(options.publicActorId, roles);
    };
    return schema.methods.replacePublicAccess = function(roles) {
      if (roles == null) roles = null;
      return this.replaceAccess(options.publicActorId, roles);
    };
  };

}).call(this);
