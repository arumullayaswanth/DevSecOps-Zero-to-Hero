package main

import (
	"fmt"
	"net/http"
	"os/user"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		u, _ := user.Current()
		fmt.Fprintf(w, "DevSecOps Container Security Demo\nRunning as: %s (UID: %s)\n", u.Username, u.Uid)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})

	fmt.Println("Server running on port 8080")
	http.ListenAndServe(":8080", nil)
}
