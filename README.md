## About mongoose-plugins-accessible-by


A simple plugin that adds an accessibleBy field to a mongoose schema to be
able to determine access rights for models belonging to this schema.

Caveat:

This plugin is designed for systems where you do not need to browse over large
collections and filter by access rights. If you need that you would have to put
in some extra work.

## Install

npm install mongoose-plugins-accessible-by

## Concepts
A resource is the object you want to secure. It contains an accessibleBy array, which is provided and managed by this plugin

A role (or scope) grants rights that you define. Typical roles are read, write, admin.

An actor is a person, but could also be the public (as any person), or group or whatever you come up with. Actors are referenced through an actorId, and internally have the format
	actorId : String
	displayName : String
	image:
		height: Number
		width: Number
		url: String
	objectType : String 

which is based on the activitystrea.ms format. You can simply use the actorId string in lieu of a full actor object, but you might want to use the actor object if you provide end user display for the roles and want to cache the display values.

## Usage (Coffeescript)
  
	mongoose = require 'mongoose'
	pluginAccessibleBy = require 'mongoose-plugins-accessible-by'

	YourSchema = new mongoose.Schema
		name : 
		type : String
	YourSchema.plugin pluginAccessibleBy.accessibleBy, defaultIsPublic : true
	YourModel = mongoose.model "YourModel",YourSchema
	model = new YourModel name : 'some resource name
  
At this point you have initialized a new model that contains an accessibleBy field. 
By passing the defaultIsPublic option we also ensured that it contains an entry that allows public read access to the model.
You can now do the following:
	model.canActorAccess(actor || actorId,role)
	model.canPublicAccess(role)
	model.canPublicRead()
	model.grantAccess(actor || actorId, role || roles)
	model.revokeAccess(actor || actorId, <nothing> || null || role || roles)
	model.replaceAccess(actor || actorId, <nothing> || null || role || roles)
	model.grantPublicAccess(role || roles)
	model.grantPublicReadOnlyAccess()
	model.revokePublicAccess( <nothing> || null || role || roles)
	model.replacePublicAccess(<nothing> || null || role || roles)
  
Please note that you need to save your model after you make changes. The plugin marks the model as modified though.

## Advertising :)

Check out 

* http://scottyapp.com

Follow us on Twitter at 

* @getscottyapp
* @martin_sunset

and like us on Facebook please. Every mention is welcome and we follow back.


## Release Notes


### 0.0.1

* First version

## Internal Stuff

* npm run-script watch

# Publish new version

* Change version in package.json
* git tag -a v0.0.1 -m 'version 0.0.1'
* git push --tags
* npm publish

## Contributing to mongoose-plugins-accessible-by
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the package.json, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 ScottyApp, Inc. See LICENSE for
further details.


