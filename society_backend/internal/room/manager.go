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
    Code                 string
    Players              map[string]*Player
    Mutex                sync.Mutex
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
        Code:                 code,
        Players:              make(map[string]*Player),
        CampaignTimerRunning: false,
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

    // Respond to joining player
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "playerID": id,
    })

    // Notify all players
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

        //--------------------------------------------------
        // COUNTDOWN
        //--------------------------------------------------
        case "start_countdown":
            m.Broadcast(code, []byte(`{"type":"start_countdown"}`))

        //--------------------------------------------------
        // NOMINATION
        //--------------------------------------------------
        case "nomination":
            rawRole, ok := data["role"].(string)
            if !ok {
                log.Println("Invalid role from client")
                break
            }

            room.Mutex.Lock()
            player.RoleWant = rawRole

            // Check if all players have chosen a role
            allChosen := true
            for _, p := range room.Players {
                if p.Conn != nil && p.RoleWant == "" {
                    allChosen = false
                    break
                }
            }

            room.Mutex.Unlock()

            // Broadcast nomination update
            m.Broadcast(code, []byte(fmt.Sprintf(
                `{"type":"nomination","player":"%s","role":"%s"}`,
                player.Name, rawRole,
            )))

            // If all players have nominated → start campaigning
            if allChosen {
                log.Println("All players nominated — starting campaigning stage.")

                m.Broadcast(code, []byte(`{"type":"start_campaigning"}`))

                room.Mutex.Lock()
                if !room.CampaignTimerRunning {
                    room.CampaignTimerRunning = true
                    go m.StartCampaignTimer(code)
                }
                room.Mutex.Unlock()
            }


        //--------------------------------------------------
        // START CAMPAIGNING + start global backend timer
        //--------------------------------------------------
        case "start_campaigning":
            m.Broadcast(code, []byte(`{"type":"start_campaigning"}`))

            room.Mutex.Lock()
            alreadyRunning := room.CampaignTimerRunning
            if !alreadyRunning {
                room.CampaignTimerRunning = true
                go m.StartCampaignTimer(code)
            }
            room.Mutex.Unlock()
            
        // CHAT SYSTEM
        case "chat":
            text, _ := data["text"].(string)

            // broadcast chat to everyone with player's name
            msg := map[string]string{
                "type": "chat",
                "from": player.Name,
                "text": text,
            }
            jsonData, _ := json.Marshal(msg)
            m.Broadcast(code, jsonData)



        //--------------------------------------------------
        // START VOTING
        //--------------------------------------------------
        case "start_voting":
            m.Broadcast(code, []byte(`{"type":"start_voting","options":["President","Chief Justice","Department of Education","Department of Labor","Department of Construction"]}`))

        //--------------------------------------------------
        // DEFAULT (broadcast raw messages)
        //--------------------------------------------------
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

    // Time’s up → voting begins
    m.Broadcast(code, []byte(`{"type":"start_voting","options":["President","Chief Justice","Department of Education","Department of Labor","Department of Construction"]}`))


    // Reset so future games can run
    room := m.Rooms[code]
    room.Mutex.Lock()
    room.CampaignTimerRunning = false
    room.Mutex.Unlock()
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
