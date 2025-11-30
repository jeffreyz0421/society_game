package main

import (
    "log"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"

    // FIXED: use your module name
    "society_backend/internal/room"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
    // initialize room manager
    manager := room.NewManager()

    // router
    r := mux.NewRouter()

    // REST: create / join room
    r.HandleFunc("/create", manager.HandleCreateRoom).Methods("POST")
    r.HandleFunc("/join", manager.HandleJoinRoom).Methods("POST")

    // WebSocket: /ws/{code}/{playerID}
    r.HandleFunc("/ws/{code}/{playerID}", func(w http.ResponseWriter, r *http.Request) {
        conn, err := upgrader.Upgrade(w, r, nil)
        if err != nil {
            log.Println("WS upgrade error:", err)
            return
        }
        manager.HandleWS(w, r, conn)
    })

    log.Println("🚀 Server running at http://localhost:8080")
    http.ListenAndServe(":8080", r)
}
