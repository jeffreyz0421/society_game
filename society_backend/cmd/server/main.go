package main

import (
    "log"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"
    "society_backend/internal/room"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true }, // 🔥 allow WS from anywhere
}

func main() {
    manager := room.NewManager()

    r := mux.NewRouter()

    // 🔥 GLOBAL CORS FIX
    r.Use(func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Access-Control-Allow-Origin", "*")
            w.Header().Set("Access-Control-Allow-Headers", "*")
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            if r.Method == "OPTIONS" {
                return
            }
            next.ServeHTTP(w, r)
        })
    })

    // REST endpoints
    r.HandleFunc("/create", manager.HandleCreateRoom).Methods("POST", "OPTIONS")
    r.HandleFunc("/join", manager.HandleJoinRoom).Methods("POST", "OPTIONS")

    // Websocket
    r.HandleFunc("/ws/{code}/{playerID}", func(w http.ResponseWriter, r *http.Request) {
        conn, err := upgrader.Upgrade(w, r, nil)
        if err != nil {
            log.Println("WS error:", err)
            return
        }
        manager.HandleWS(w, r, conn)
    })

    log.Println("🚀 Server running at :8080")
    http.ListenAndServe(":8080", r)
}
