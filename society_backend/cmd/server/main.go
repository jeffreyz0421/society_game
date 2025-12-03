package main

import (
    "log"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"
    "society_backend/internal/room"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
    manager := room.NewManager()
    r := mux.NewRouter()

    //--------------------------------------------------
    // CORS MIDDLEWARE
    //--------------------------------------------------
    r.Use(func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Access-Control-Allow-Origin", "*")
            w.Header().Set("Access-Control-Allow-Headers", "*")
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

            if r.Method == "OPTIONS" {
                w.WriteHeader(http.StatusOK)
                return
            }

            next.ServeHTTP(w, r)
        })
    })

    //--------------------------------------------------
    // REST ROUTES
    //--------------------------------------------------
    r.HandleFunc("/create", manager.HandleCreateRoom).Methods("POST", "OPTIONS")
    r.HandleFunc("/join", manager.HandleJoinRoom).Methods("POST", "OPTIONS")

    //--------------------------------------------------
    // WEBSOCKET ROUTE
    //--------------------------------------------------
    r.HandleFunc("/ws/{code}/{playerID}", func(w http.ResponseWriter, r *http.Request) {
        conn, err := upgrader.Upgrade(w, r, nil)
        if err != nil {
            log.Println("WebSocket Upgrade ERROR:", err)
            return
        }
        manager.HandleWS(w, r, conn)
    })

    //--------------------------------------------------
    // SERVER START
    //--------------------------------------------------
    log.Println("🚀 Global Society Backend running on port :8080")
    if err := http.ListenAndServe(":8080", r); err != nil {
        log.Fatal("Server crashed:", err)
    }
}
