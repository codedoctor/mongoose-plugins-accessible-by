should = require 'should'
mongoose = require 'mongoose'

helper = require './support/helper'
index = require '../src/index'
TestSchema = require './fixtures/test-schema'

describe 'WHEN actually saving that stuff', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'on save the default', ->
    it 'should have saved it', (done) ->
      helper.mongo.collection('testmodels').count (err,originalCount) ->
        return done(err) if err
        originalCount = originalCount || 0
        
        TestSchema.plugin index.accessibleBy, defaultIsPublic : true
        TestModel = mongoose.model "TestModel",TestSchema

        model = new TestModel( name : 'test')

        model.save (err) ->
          return done err if err
    
          helper.mongo.collection('testmodels').count (err,res) ->
            return done(err) if err
            res.should.eql originalCount + 1
    
            done()
            
  describe 'on save an update', ->
    it 'should have saved it', (done) ->
      TestSchema.plugin index.accessibleBy, defaultIsPublic : true
      TestModel = mongoose.model "TestModel",TestSchema

      model = new TestModel( name : 'test')
      originalId = model._id

      model.save (err) ->
        return done err if err
        TestModel.findOne _id : originalId, (err,model) ->
          return done(err) if err
          should.exist model
          model.grantPublicAccess 'write'
          model.save (err) ->
            return done err if err

            helper.mongo.collection('testmodels').findOne _id : originalId, (err,res) ->
              return done(err) if err
              should.exist res
              res.should.have.property 'accessibleBy'
              res.accessibleBy.should.have.property 'length',1
              res.accessibleBy[0].should.have.property 'actor'
              res.accessibleBy[0].should.have.property 'roles'
              res.accessibleBy[0].actor.should.have.property 'actorId'
              res.accessibleBy[0].roles.should.have.property 'length',2
              res.accessibleBy[0].roles[0].should.equal "read"
              res.accessibleBy[0].roles[1].should.equal "write"


              done()
                    