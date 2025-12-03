package room

import (
    "encoding/json"
    "fmt"
    "log"
    "math/rand"
    "net/http"
    "sync"
    "time"

    "github.com/gorilla/mux"
    "github.com/gorilla/websocket"
)

/// ------------------------------------------------------
/// TYPES
/// ------------------------------------------------------

type Player struct {
    ID       string
    Name     string
    RoleWant string
    Gold     int
    Conn     *websocket.Conn
}

type Room struct {
    Code          string
    Players       map[string]*Player
    Mutex         sync.Mutex
    CampaignTimerRunning bool
}

type Manager struct {
    Rooms map[string]*Room
}

/// ------------------------------------------------------
/// INITIALIZER
/// ------------------------------------------------------

func NewManager() *Manager {
    return &Manager{
        Rooms: make(map[string]*Room),
    }
}

/// ------------------------------------------------------
/// CREATE ROOM
/// ------------------------------------------------------

func (m *Manager) HandleCreateRoom(w http.ResponseWriter, r *http.Request) {
    code := generateRoomCode()

    room := &Room{
        Code:    code,
        Players: make(map[string]*Player),
    }

    m.Rooms[code] = room

    joinURL := "https://society-game-web.onrender.com/?room=" + code

    resp := map[string]string{
        "code":    code,
        "joinURL": joinURL,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}

/// ------------------------------------------------------
/// JOIN ROOM
/// ------------------------------------------------------

func (m *Manager) HandleJoinRoom(w http.ResponseWriter, r *http.Request) {
    type JoinRequest struct {
        Code string `json:"code"`
        Name string `json:"name"`
    }

    var req JoinRequest
    json.NewDecoder(r.Body).Decode(&req)

    room, ok := m.Rooms[req.Code]
    if !ok {
        http.Error(w, "Room not found", http.StatusNotFound)
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

    // Notify players
    m.Broadcast(req.Code, []byte(fmt.Sprintf(
        `{"type":"player_joined","name":"%s"}`, req.Name,
    )))
}

/// ------------------------------------------------------
/// WEBSOCKET HANDLER
/// ------------------------------------------------------

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

    for {
        _, msg, err := conn.ReadMessage()
        if err != nil {
            break
        }

        var data map[string]interface{}
        json.Unmarshal(msg, &data)

        msgType, _ := data["type"].(string)

        switch msgType {

        // COUNTDOWN
        case "start_countdown":
            m.Broadcast(code, []byte(`{"type":"start_countdown"}`))
            break

        // NOMINATION
        case "nomination":
            rawRole, ok := data["role"].(string)
            if !ok {
                log.Println("Invalid role from client")
                break
            }

            room.Mutex.Lock()
            player.RoleWant = rawRole
            room.Mutex.Unlock()

            m.Broadcast(code, []byte(fmt.Sprintf(
                `{"type":"nomination","player":"%s","role":"%s"}`,
                player.Name, rawRole,
            )))
            break

        // START CAMPAIGNING
        case "start_campaigning":
            m.Broadcast(code, []byte(`{"type":"start_campaigning"}`))

            room.Mutex.Lock()
            alreadyRunning := room.CampaignTimerRunning
            if !alreadyRunning {
                room.CampaignTimerRunning = true
                go m.StartCampaignTimer(code)
            }
            room.Mutex.Unlock()
            break

        // START VOTING
        case "start_voting":
            m.Broadcast(code, []byte(`{"type":"start_voting"}`))
            break

        // DEFAULT
        default:
            m.Broadcast(code, msg)
        }
    }
}

/// ------------------------------------------------------
/// BACKEND TIMER
/// ------------------------------------------------------

func (m *Manager) StartCampaignTimer(code string) {
    duration := 120 // 2 minutes

    for duration >= 0 {
        m.Broadcast(code, []byte(fmt.Sprintf(
            `{"type":"campaign_timer","time":%d}`, duration,
        )))

        time.Sleep(1 * time.Second)
        duration--
    }

    m.Broadcast(code, []byte(`{"type":"start_voting"}`))
}

/// ------------------------------------------------------
/// BROADCAST
/// ------------------------------------------------------

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

/// ------------------------------------------------------
/// HELPERS
/// ------------------------------------------------------

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
