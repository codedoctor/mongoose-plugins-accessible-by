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
    it 'should exist', (done) ->
      should.exist index
      done()

  describe 'adding the plugin', ->
    it 'should work', (done) ->
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
      
      done()
      
