request = require 'supertest'
app     = require '../server.js'
assert  = require 'assert'

r = request(app)

#########################################################

missing_route = ->
    describe 'Missing route', ->

        paths = [
            '/'
            '/random'
            '/x'
            '/x/random'
        ]

        paths.forEach (path)->
            it "#{path} goes to 404", (done)->
                r.get(path).expect(404, done)


#########################################################

add_item = ->
    describe 'Add item', ->
        p = null

        beforeEach (done)->
            p = r.post("/x").set('Content-Type', 'application/json')
            done()

        describe 'POST /x', ->

            #----------------------------------------------
            it 'returns 400 if content is missing', (done)->
                p.expect(400, done)

            #----------------------------------------------
            it 'returns 400 if there is no armor', (done)->
                p.send({ blah: 1 }).expect(400, done)

            #----------------------------------------------
            it 'returns 201 if there is armor', (done)->
                p.send({ armor: "something" })
                    .end (err, res)->
                        assert.equal(res.status, 201, "201 OK")
                        assert.ok(res.body.id, "id present")
                        done()

#########################################################

retrieve_items = ->
    describe 'Retrieve items', ->
        p = null
        result = null

        beforeEach (done)->
            p = r.post("/x")
                .set('Content-Type', 'application/json')
                .send({ armor: "something" })
                .end (err, res)->
                    result = res.body
                    done()

        describe "GET /x/:id", ->
            it "returns 404 if id not found", (done)->
                r.get("/x/562075c6850ddb4a24c9b005")
                    .set('Content-Type', 'application/json')
                    .expect(404, done)

            it "returns 200 if id is found", (done)->
                r.get("/x/#{result.id}")
                    .set('Content-Type', 'application/json')
                    .expect(200, done)

            it "returns the json stored", (done)->
                r.get("/x/#{result.id}")
                    .set('Content-Type', 'application/json')
                    .end (err, res)->
                        assert.equal(res.body.armor, "something")
                        done()

            it "save proper data in the DB", (done)->
                r.get("/x/#{result.id}")
                    .set('Content-Type', 'application/json')
                    .end (err, res)->
                        app.items.findOne { _id: app.ObjectId(result.id) }, (e, r)->
                            assert.equal(r.armor, "something")
                            done()

#########################################################

describe 'Bootstrap', ->
    it 'Created a database', (done)->
        app.bootstrap ->
            assert.ok app.db

            # Cleanup
            app.items.remove({})

            # Tests
            missing_route()
            add_item()
            retrieve_items()

            done()
