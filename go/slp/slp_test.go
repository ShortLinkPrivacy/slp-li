package slp

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func Test404(t *testing.T) {
	paths := [...]string{"/", "/x", "/x/123123"}

	Init()
	w := httptest.NewRecorder()

	for i := 0; i < len(paths); i++ {
		req, _ := http.NewRequest("GET", paths[i], nil)
		r.ServeHTTP(w, req)
		if w.Code != 404 {
			t.Error("Should have gotten 404 on " + paths[i])
		}
	}

}

func TestPost(t *testing.T) {
	Init()
	w := httptest.NewRecorder()

	req, _ := http.NewRequest("POST", "/x", nil)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Body", "{\"body\":\"testing\"}")
	r.ServeHTTP(w, req)

	if w.Code != 201 {
		t.Error("Did not receive 201", w.Code)
	}

}
