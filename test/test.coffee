should = require 'should'
mongoose = require 'mongoose'

helper = require './support/helper'
index = require '../src/index'
TestSchema = require './fixtures/test-schema'

        

describe 'WHEN working with the plugin', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'index', ->
    it '1. should exist', (done) ->
      should.exist index
      done()

  describe 'adding the plugin', ->
    it '2. should work', (done) ->
      TestSchema.plugin index.accessibleBy, defaultIsPublic : true
      TestModel = mongoose.model "TestModel",TestSchema
  
      model = new TestModel( name : 'test')
      should.exist model
      model.should.have.property 'name', 'test'
      model.should.have.property 'accessibleBy'
      model.accessibleBy.should.have.property 'length',1
      model.accessibleBy[0].should.have.property 'actor'
      model.accessibleBy[0].should.have.property 'roles'
      model.accessibleBy[0].actor.should.have.property 'actorId'
      model.accessibleBy[0].roles.should.have.property 'length',1
      model.accessibleBy[0].roles[0].should.equal "read"
      model.canActorAccess("dummy","whatever").should.equal false
      model.canPublicRead().should.equal true
      done()

  describe 'when invoking grantPublicAccess', ->
    it '3. should add a write role', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.grantPublicAccess 'write'
      model.accessibleBy.should.have.property 'length',1
      model.canPublicRead().should.equal true
      model.canPublicAccess("write").should.equal true
      model.canPublicAccess("cook-coffee").should.equal false
      model.accessibleBy[0].roles.length.should.equal 2
      model.grantPublicAccess 'write'
      model.accessibleBy[0].roles.length.should.equal 2
      done()

  describe 'WHEN invoking revokePublicAccess', ->
    it '4. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.revokePublicAccess 'read'
      model.accessibleBy.should.have.property 'length',0
      done()
    it '5. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.revokePublicAccess ['read','dummy']
      model.accessibleBy.should.have.property 'length',0
      done()
    it '6. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.revokePublicAccess()
      model.accessibleBy.should.have.property 'length',0
      done()
    it '7. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.revokePublicAccess ['dummy']
      model.accessibleBy.should.have.property 'length',1
      done()
    it '8. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.grantPublicAccess ['admin','write']
      model.accessibleBy[0].roles.should.have.property 'length',3
      model.revokePublicAccess ['read']
      model.accessibleBy.should.have.property 'length',1
      model.accessibleBy[0].roles.should.have.property 'length',2
      
      model.canPublicAccess("read").should.equal false
      model.canPublicAccess("write").should.equal true
      model.canPublicAccess("admin").should.equal true
      done()

    it '9. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.grantPublicAccess ['admin','write']
      model.revokePublicAccess ['read','admin','write']
      model.accessibleBy.should.have.property 'length',0
      done()

  describe 'WHEN invoking replacePublicAccess', ->
    it '10. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.replacePublicAccess()
      model.accessibleBy.should.have.property 'length',0
      done()
    it '11. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.replacePublicAccess 'write'
      model.accessibleBy.should.have.property 'length',1
      model.canPublicAccess("read").should.equal false
      model.canPublicAccess("write").should.equal true
      done()
    it '12. should remove the accessibleBy element', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.replacePublicAccess ['read','write']
      model.accessibleBy.should.have.property 'length',1
      model.canPublicAccess("read").should.equal true
      model.canPublicAccess("write").should.equal true
      done()

  describe 'when testing grantAccess on a different actor', ->
    it '13. should add a write role', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      #console.log "Phase1: #{JSON.stringify(model)}"
      model.accessibleBy.should.have.property 'length',1
      model.grantAccess 'frankid','write'
      model.accessibleBy.should.have.property 'length',2
      #console.log "a"
      model.canActorAccess('frankid',"write").should.equal true
      #console.log "b"
      model.canActorAccess('frankid',"cook-coffee").should.equal false
      #console.log "c"
      model.canActorAccess({actorId : 'frankid'},"write").should.equal true
      #console.log "d"
      model.canActorAccess({actorId : 'frankid'},"cook-coffee").should.equal false
      #console.log "e"
      model.canActorAccess({actorId : 'johnnyid'},"cook-coffee").should.equal false
      #console.log "f"
      done()
  
  describe 'when granting/revoking/replacing', ->
    it '14. should return the model to be chainable', (done) ->   
      TestModel = mongoose.model "TestModel",TestSchema
      model = new TestModel( name : 'test')
      model.accessibleBy.should.have.property 'length',1
      model.grantAccess('frankid','write').should.equal model
      model.revokeAccess('frankid','write').should.equal model
      model.replaceAccess('frankid','admin').should.equal model
      done()
      
 