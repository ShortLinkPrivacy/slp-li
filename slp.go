package main

import (
	"github.com/gin-gonic/gin"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
	"log"
	"time"
)

var (
	session *mgo.Session
	items   *mgo.Collection
)

type Item struct {
	Id          bson.ObjectId `bson:"_id" json:"id"`
	Body        string        `json:"body" binding:"required"`
	TimeToLive  int           `bson:"timeToLive" json:"timeToLive"`
	CreatedDate time.Time     `bson:"createdDate" json:"-"`
	Ip          string        `json:"-"`
	ExtVersion  string        `bson:"extVersion" json:"-"`
}

type Success struct {
	Success bool        `json:"success"`
	Error   string      `json:"error"`
	Value   interface{} `json:"value"`
}

func main() {
	session, err := mgo.Dial("localhost")
	defer session.Close()
	if err != nil {
		log.Fatalf("Error connecting: %v", err)
	}
	items = session.DB("pgp").C("items")

	r := gin.New()
	r.POST("/x", postItem)
	r.GET("/x/:id", getItem)
	r.Run(":5000")
}

func view(item Item) string {
	return `
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>Short Link Privacy Message</title>
        <style type="text/css">
            body { font-family: sans-serif; background-color: #fff; }
            #content { width: 500px; margin-left: auto; margin-right: auto; }
            .slp {}
            .slp a { color: #00f; font-weight: bold; }
            pre { background-color: #eee; padding: 10px; border: 1px dotted #aaa; }
        </style>
      </head>
      <body>
        <div id="content">
            <h1>PGP Encrypted Message</h1>
            <p class="slp">
                Please install the <a href="">Short Link Privacy</a> browser
                plugin to have this message seamlessly decrypt in your browser.
            </p>
            <pre>
    ` + item.Body + `
            </pre>
            <small class="footer">
                <a href="https://en.wikipedia.org/wiki/Pretty_Good_Privacy">What is PGP?</a> |
                <a href="">What is SLP?</a>
            </small>
        </div>
      </body>
    </html>
	 `
}

func postItem(c *gin.Context) {
	var item Item

	// Fill in the auto values
	item.Id = bson.NewObjectId()
	item.Ip = c.Request.Header.Get("x-real-ip")
	item.CreatedDate = time.Now()

	if err := c.BindJSON(&item); err == nil {
		if err = items.Insert(&item); err == nil {
			result := Success{true, "", item}
			c.JSON(201, result)
		} else {
			c.String(500, "Server Error")
		}
	} else {
		c.String(400, "Missing required fields")
	}
}

func getItem(c *gin.Context) {
	var item Item

	id := c.Param("id")

	if !bson.IsObjectIdHex(id) {
		c.String(404, "Not found")
		return
	}

	oid := bson.ObjectIdHex(id)
	err := items.FindId(oid).One(&item)

	// Not found
	if err != nil {
		c.String(404, "Not found")
		return
	}

	// Expired
	if item.CreatedDate.Second()+item.TimeToLive > time.Now().Second() {
		c.String(401, "Gone")
		return
	}

	if c.Request.Header.Get("Content-Type") == "application/json" {
		result := Success{true, "", item}
		c.JSON(200, &result)
	} else {
		c.Header("Content-Type", "text/html")
		c.String(200, view(item))
	}

}
