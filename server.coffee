express = require 'express'
bodyParser = require 'body-parser'
mongodb = require 'mongodb'
config = require 'config'
log4js = require 'log4js'

# Configuration options
#=================================================================
url = config.get 'mongo.url'
port = config.get('express.port')

# Logger config
#=================================================================
log4js.configure
    appenders: config.get('log4js.appenders')
logger = log4js.getLogger 'app'
logger.setLevel(config.get('log4js.level'))

# Web app config
#=================================================================
app = express()
app.set('views', './views')
app.set('view engine', 'jade')

# Middleware
app.use(bodyParser.json())
app.use (req, res, next)->
    logger.info("#{req.method} #{req.path}")
    next()

# Bootstrap
#=================================================================
bootstrap = app.bootstrap = (code)->
    mongodb.MongoClient.connect url, (err, _db)->
        if err
            logger.error "Error: #{err}"
            return

        app.ObjectId = mongodb.ObjectId
        app.db = _db
        app.items = _db.collection('items')
        code()

# Routes
#=================================================================
app.get '/x/:id', (req, res)->

    id = req.params.id
    objId = null

    # Must be an ObjectId
    try
        objId = new mongodb.ObjectId id
    catch e
        return res.sendStatus 404

    # Not json? Return a text with a link to install the extension
    # TODO: Send a full HTML with links here
    if req.get('Content-Type') isnt "application/json"
        res.statusCode = 200
        res.send "Please download and install this Chrome plugin to read this message"
        return

    # Find the id in items
    app.items.findOne { _id: objId }, (err, result)->
        if err?
            logger.error "findOne(#{id}) returned error: #{err}"
            res.sendStatus 500
        else if result?
            res.statusCode = 200
            res.json result
        else
            res.sendStatus 404


app.post '/x', (req, res)->
    #logger.trace "req.headers", req.headers
    #logger.trace "req.body", req.body
    payload = req.body

    err400 = (msg)->
        res.statusCode = 400
        res.json { error: msg }

    if not payload?
        return err400 "Payload missing"

    unless payload.armor?
        return err400 "armor not defined"

    # TODO: find a way to limit POSTs to internal data only, so
    # idiots don't begin using this service as a free anonymous
    # key-value items

    app.items.insertOne payload, (err, result)->
        if err?
            logger.error "insertOne (#{payload}) resulted in error: #{err}"
            res.sendStatus = 500
        else
            res.statusCode = 201
            res.json { id: result.insertedId }


# Main
#=================================================================
if require.main == module
    bootstrap ->
        app.listen port, ->
            logger.info "The server is running on port #{port}"

module.exports = app
