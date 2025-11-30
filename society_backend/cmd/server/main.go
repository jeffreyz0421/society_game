package main

import (
    "log"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"
    "society_backend/internal/room"
)

// GLOBAL WebSocket upgrader
var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true }, // allow all origins
}

func main() {
    manager := room.NewManager()

    r := mux.NewRouter()

    // ----------------------------------------------------
    // 🌍 GLOBAL CORS MIDDLEWARE (needed for Render + Web)
    // ----------------------------------------------------
    r.Use(func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

            // Allow any site to call this backend
            w.Header().Set("Access-Control-Allow-Origin", "*")

            // Allow any headers the browser sends
            w.Header().Set("Access-Control-Allow-Headers", "*")

            // Allow REST & OPTIONS
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

            // Browser OPTIONS preflight
            if r.Method == "OPTIONS" {
                w.WriteHeader(http.StatusOK)
                return
            }

            next.ServeHTTP(w, r)
        })
    })

    // ----------------------------------------------------
    // REST ENDPOINTS
    // ----------------------------------------------------
    r.HandleFunc("/create", manager.HandleCreateRoom).Methods("POST", "OPTIONS")
    r.HandleFunc("/join", manager.HandleJoinRoom).Methods("POST", "OPTIONS")

    // ----------------------------------------------------
    // WEBSOCKET ENDPOINT
    // ----------------------------------------------------
    r.HandleFunc("/ws/{code}/{playerID}", func(w http.ResponseWriter, r *http.Request) {
        conn, err := upgrader.Upgrade(w, r, nil)
        if err != nil {
            log.Println("WebSocket Upgrade ERROR:", err)
            return
        }
        manager.HandleWS(w, r, conn)
    })

    // ----------------------------------------------------
    // START SERVER
    // ----------------------------------------------------
    log.Println("🚀 Global Society Backend running on port :8080")
    if err := http.ListenAndServe(":8080", r); err != nil {
        log.Fatal("Server crashed:", err)
    }
}
