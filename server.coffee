express = require 'express'
bodyParser = require 'body-parser'
mongodb = require 'mongodb'
MongoClient = mongodb.MongoClient
ObjectId = mongodb.ObjectId
config = require 'config'
log4js = require 'log4js'

url = config.get 'mongo.url'

# -----------------------------------------
# Setup
# -----------------------------------------

# Logger
log4js.configure {
    appenders: config.get('log4js.appenders')
}
logger = log4js.getLogger 'app'
logger.setLevel(config.get('log4js.level'))

# Web application
app = express()

# -----------------------------------------
# Express middleware
# -----------------------------------------
app.use(bodyParser.json())
app.use (req, res, next)->
    logger.info("#{req.method} #{req.path}")
    next()

# -----------------------------------------
# Routes
# -----------------------------------------

app.get '/x/:id', (req, res)->

    id = req.params.id
    objId = null

    # Must be an ObjectId
    try
        objId = new ObjectId id
    catch e
        return res.sendStatus 404

    # Not json? Return a text with a link to install the extension
    # TODO: Send a full HTML with links here
    unless req.get('Content-Type') == "application/json"
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


# Bootstrap

app.bootstrap = (code)->
    MongoClient.connect url, (err, _db)->
        app.ObjectId = ObjectId
        app.db = _db
        app.items = _db.collection('items')
        code()

if require.main == module
    app.bootstrap ->
        port = config.get('express.port')
        app.listen port, ->
            logger.info "The server is running on port #{port}"

module.exports = app