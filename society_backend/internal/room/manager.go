package room

import (
    "encoding/json"
    "log"
    "math/rand"
    "net/http"
    "sync"
    "time"
    "fmt"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"
)

// ------------------------------------------
// TYPES
// ------------------------------------------

type Player struct {
    ID       string
    Name     string
    RoleWant string
    Gold     int
    Conn     *websocket.Conn
}

type Room struct {
    Code    string
    Players map[string]*Player
    Mutex   sync.Mutex
}

type Manager struct {
    Rooms map[string]*Room
}

// ------------------------------------------

func NewManager() *Manager {
    return &Manager{
        Rooms: make(map[string]*Room),
    }
}

// ------------------------------------------
// CREATE ROOM
// ------------------------------------------

func (m *Manager) HandleCreateRoom(w http.ResponseWriter, r *http.Request) {
    code := generateRoomCode()

    room := &Room{
        Code:    code,
        Players: make(map[string]*Player),
    }

    m.Rooms[code] = room

    // 🔥 CHANGE THIS TO YOUR WIFI IP
    joinURL := "https://society-game-web.onrender.com/?room=" + code

    w.Header().Set("Content-Type", "application/json")

    resp := map[string]string{
        "code":    code,
        "joinURL": joinURL,
    }

    json.NewEncoder(w).Encode(resp)
}

// ------------------------------------------
// JOIN ROOM
// ------------------------------------------

func (m *Manager) HandleJoinRoom(w http.ResponseWriter, r *http.Request) {
    type JoinRequest struct {
        Code string `json:"code"`
        Name string `json:"name"`
    }

    var req JoinRequest
    json.NewDecoder(r.Body).Decode(&req)

    room, ok := m.Rooms[req.Code]
    if !ok {
        http.Error(w, "Room not found", 404)
        return
    }

    id := generatePlayerID()

    room.Mutex.Lock()
    room.Players[id] = &Player{
        ID:       id,
        Name:     req.Name,
        RoleWant: "",
        Gold:     10,
        Conn:     nil,
    }
    room.Mutex.Unlock()

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "playerID": id,
    })
    
    m.Broadcast(req.Code, []byte(fmt.Sprintf(
    `{"type":"player_joined","name":"%s"}`,
    req.Name,
)))
}

// ------------------------------------------
// WEBSOCKET
// ------------------------------------------

func (m *Manager) HandleWS(w http.ResponseWriter, r *http.Request, conn *websocket.Conn) {
    vars := mux.Vars(r)
    code := vars["code"]
    id := vars["playerID"]

    room, ok := m.Rooms[code]
    if !ok {
        log.Println("WS room not found")
        conn.Close()
        return
    }

    room.Mutex.Lock()
    player := room.Players[id]
    player.Conn = conn
    room.Mutex.Unlock()

    log.Println("Player connected:", id)

    // Listen for messages
    for {
        _, msg, err := conn.ReadMessage()
        if err != nil {
            break
        }

        log.Printf("WS message from %s: %s", id, string(msg))
        m.Broadcast(code, msg)
    }
}

// ------------------------------------------
// BROADCAST
// ------------------------------------------

func (m *Manager) Broadcast(code string, data []byte) {
    room := m.Rooms[code]

    room.Mutex.Lock()
    defer room.Mutex.Unlock()

    for _, p := range room.Players {
        if p.Conn != nil {
            p.Conn.WriteMessage(websocket.TextMessage, data)
        }
    }
}

// ------------------------------------------
// HELPERS
// ------------------------------------------

func generateRoomCode() string {
    letters := []rune("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    rand.Seed(time.Now().UnixNano())

    b := make([]rune, 4)
    for i := range b {
        b[i] = letters[rand.Intn(len(letters))]
    }
    return string(b)
}

func generatePlayerID() string {
    return generateRoomCode()
}
