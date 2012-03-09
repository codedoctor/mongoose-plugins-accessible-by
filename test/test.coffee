should = require 'should'
helper = require './support/helper'

index = require '../src/index'
someObjectId = "4eed2d88c3dedf0d0300001c"
otherObjectId = "4eed2d88c3dedf0d0300001a"


describe 'WHEN working with the plugin', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'index', ->
    it 'should exist', ->
      should.exist index
