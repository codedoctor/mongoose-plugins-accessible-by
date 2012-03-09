fs = require 'fs'
mongoose = require 'mongoose'
_ = require 'underscore'
DatabaseCleaner = require 'database-cleaner'
async = require 'async'
mongoskin = require 'mongoskin'

class Helper
  
  database :  'mongodb://localhost/mongoose_plugins_test' 
    
  fixturePath: (fileName) =>
    "#{__dirname}/../fixtures/#{fileName}"

  tmpPath: (fileName) =>
    "#{__dirname}/../tmp/#{fileName}"

  cleanTmpFiles: (fileNames) =>
    for file in fileNames
      try
        fs.unlinkSync @tmpPath(file)
      catch ignore

  loadJsonFixture: (fixtureName) =>
    data = fs.readFileSync @fixturePath(fixtureName), "utf-8"
    JSON.parse data

  # Connect to the test database.
  connectDatabase: () =>
    mongoose.connect @database

  cleanDatabase : (cb) =>
    return cb(null) # Stupid cleaner not working, bypassing
    console.log "CLEANING Database #{@database}"
    databaseCleaner = new DatabaseCleaner('mongodb')
    databaseCleaner.clean mongoose.createConnection(@database).db, (err) =>
      return cb(err) if err
      cb null
      
  start: (obj = {}, done) =>
    _.defaults obj, { initDatabase : true,cleanDatabase : true, createApps : true }
    obj.cleanDatabase = true if obj.initDatabase
    @mongo = mongoskin.db(@database)
    
    @connectDatabase()

    stuff = []

    if obj.cleanDatabase
      stuff.push (cb) => 
        @cleanDatabase(cb)
    
    async.series stuff, () => done()
    
        
  stop: (done) =>
    # Should probably drop database here
    done()

module.exports = new Helper()

