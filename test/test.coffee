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
      model.canActorAccess("dummy","whatever").should.equal false
      model.canPublicRead().should.equal true
      done()

  describe 'when testing grantPublicAccess', ->
    it 'should add a write role', (done) ->   
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

    describe 'when testing grantAccess on a different actor', ->
      it 'should add a write role', (done) ->   
        TestModel = mongoose.model "TestModel",TestSchema
        model = new TestModel( name : 'test')
        model.accessibleBy.should.have.property 'length',1
        model.grantAccess 'frankid','write'
        model.accessibleBy.should.have.property 'length',2
        model.canActorAccess('frankid',"write").should.equal true
        model.canActorAccess('frankid',"cook-coffee").should.equal false
        model.canActorAccess({actorId : 'frankid'},"write").should.equal true
        model.canActorAccess({actorId : 'frankid'},"cook-coffee").should.equal false
        model.canActorAccess({actorId : 'johnnyid'},"cook-coffee").should.equal false
        done()
      
  ###
  # Returns true if the user can update this organization
  def can_update?(user)
    return false unless user
    return true if user.is_in_role?('admin')
    return true if self.accessible_by.length == 0 && self.creator == user
    return true if (self.accessible_by.select {|item| item.is_user_and_write?(user) || item.is_user_and_admin?(user) }).count > 0
    false
  end

  def can_delete?(user)
    return false unless user
    return true if user.is_in_role?('admin')
    return true if self.accessible_by.length == 0 && self.creator == user
    return true if (self.accessible_by.select {|item| item.is_user_and_write?(user) || item.is_user_and_admin?(user) }).count > 0
    false
  end

  def can_read?(user)
    return true unless self.is_private
    return false unless user
    return true if user.is_in_role?('admin')
    return true if self.accessible_by.length == 0 && self.creator == user
    return true if (self.accessible_by.select {|item| item.user == user }).count > 0
    false
  end
  
  # Creates a new element that contains all roles
  def self.new_for_all(user)
    raise ArgumentError.new("You must pass a valid user object.") unless user && user.is_a?(User)
    
    app_access = AppAccess.new(:user => user)
    app_access.roles = AppAccess::ROLES
    app_access  
  end
  
  def is_in_admin_role?
    self.roles.include?('admin')
  end
  
  def is_in_read_role?
    self.roles.include?('read')    
  end

  def is_in_write_role?
    self.roles.include?('write')    
  end

  def is_user_and_admin?(user)
    self.user == user && is_in_admin_role?
  end
  
  def is_user_and_read?(user)
    self.user == user && is_in_read_role?
  end

  def is_user_and_write?(user)
    self.user == user && is_in_write_role?
  end
  ###
