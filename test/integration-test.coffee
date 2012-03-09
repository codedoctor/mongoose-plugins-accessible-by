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