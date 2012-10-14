mongoose = require 'mongoose'

module.exports = new mongoose.Schema
      # The name of this flow document. Can 
      # be anything between 3 and 40 characters.
      name : 
        type : String
        trim: true
        required: true
        match: /.{3,40}/
