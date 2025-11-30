package messages

type ChatMessage struct {
    From    string `json:"from"`
    To      string `json:"to,omitempty"`
    Text    string `json:"text"`
}

type RallyMessage struct {
    From  string `json:"from"`
    Text  string `json:"text"`
    Gold  int    `json:"gold"`
}

type PromiseMessage struct {
    From      string `json:"from"`
    To        string `json:"to"`
    ValueOffered int `json:"valueOffered"`
}

type VoteMessage struct {
    PlayerID string `json:"playerID"`
    Role     string `json:"role"`
}

