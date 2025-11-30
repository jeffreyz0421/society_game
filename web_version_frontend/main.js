//
//  main.js  — GLOBAL ONLINE VERSION (FULLY FIXED)
//

let socket = null;
let playerID = null;
let roomCode = null;
const EMOJIS = ["😎","🤠","🙂","🥸","🤓","🙂‍↕️","😇"];
function randomEmoji() {
    return EMOJIS[Math.floor(Math.random()*EMOJIS.length)];
}
let players = [null, null, null, null, null];



// 🌍 Your deployed backend URL
const BACKEND_HTTP = "https://society-game.onrender.com";
const BACKEND_WS  = "wss://society-game.onrender.com";

// --------------------------------------------------
// UI helper
// --------------------------------------------------
function show(id) {
    document.querySelectorAll(".screen").forEach(s => s.classList.add("hidden"));
    document.getElementById(id).classList.remove("hidden");
}

// --------------------------------------------------
// JOIN ROOM
// --------------------------------------------------
function joinRoom() {
    roomCode = document.getElementById("roomCodeInput").value.trim();
    const name = document.getElementById("playerNameInput").value.trim();

    if (!roomCode || !name) {
        alert("Enter room code and name!");
        return;
    }

    fetch(`${BACKEND_HTTP}/join`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code: roomCode, name })
    })
    .then(r => r.json())
    .then(data => {
        playerID = data.playerID;
        openSocket();
    })
    .catch(err => console.error("JOIN ERR:", err));
}

// --------------------------------------------------
// OPEN WEBSOCKET (Render-safe)
// --------------------------------------------------
function openSocket() {
    socket = new WebSocket(`${BACKEND_WS}/ws/${roomCode}/${playerID}`);

    socket.onopen = () => {
        console.log("WS connected!");
        show("screen_role");
    };

    socket.onmessage = (msg) => {
        const data = JSON.parse(msg.data);
        console.log("WS MSG:", data);

        switch (data.type) {
            case "roles_available":
                renderRoles(data.roles);
                break;
                
            case "player_joined":
                addNewPlayer(data.name);
                break;

            case "chat":
                addChatMessage(data.from, data.text);
                break;

            case "start_campaign":
                show("screen_campaigning");
                break;

            case "start_voting":
                show("screen_voting");
                renderVoting(data.options);
                break;
        }
    };

    socket.onerror = (e) => console.error("WS error:", e);
    socket.onclose = () => console.warn("WS closed");
}

// --------------------------------------------------
// RENDER ROLES
// --------------------------------------------------
function renderRoles(roles) {
    const container = document.getElementById("roleList");
    container.innerHTML = "";

    roles.forEach(role => {
        const btn = document.createElement("button");
        btn.className = "roleButton";
        btn.innerText = role;

        btn.onclick = () => socket.send(JSON.stringify({
            type: "select_role",
            role
        }));

        container.appendChild(btn);
    });
}


// --------------------------------------------------
// CHAT
// --------------------------------------------------
function sendChat() {
    const input = document.getElementById("chatInput");
    const text = input.value.trim();
    if (!text) return;

    socket.send(JSON.stringify({ type: "chat", text }));
    input.value = "";
}

function addChatMessage(from, text) {
    const box = document.getElementById("chatBox");
    const el = document.createElement("div");

    el.innerHTML = `<strong>${from}:</strong> ${text}`;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
}

// --------------------------------------------------
// VOTING
// --------------------------------------------------
function renderVoting(options) {
    const container = document.getElementById("voteOptions");
    container.innerHTML = "";

    options.forEach(role => {
        const btn = document.createElement("button");
        btn.className = "voteButton";
        btn.innerText = `Vote for: ${role}`;

        btn.onclick = () =>
            socket.send(JSON.stringify({ type: "vote", role }));

        container.appendChild(btn);
    });
}


// --------------------------------------------------
// HOST ROOM
// --------------------------------------------------
let hostName = null;
let hostEmoji = null;

function finishHostSetup() {
    hostName = document.getElementById("hostNameInput").value.trim();
    if (!hostName) {
        alert("Enter your name!");
        return;
    }

    // Generate host emoji
    hostEmoji = randomEmoji();

    // Create room
    fetch(`${BACKEND_HTTP}/create`, { method: "POST" })
        .then(r => r.json())
        .then(data => {
            roomCode = data.code;
            showQRCode(data.joinURL, data.code);

            // Fill lobby with empty slots first
            setupLobbyUI();

            // Host joins room as Player 1
            joinAsHost();
        });
}
function joinAsHost() {
    fetch(`${BACKEND_HTTP}/join`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code: roomCode, name: hostName })
    })
    .then(r => r.json())
    .then(data => {
        playerID = data.playerID;
        openSocket();

        // Immediately mark host as slot #1
        players[0] = {
            name: hostName,
            emoji: hostEmoji
        };
        updateLobbyUI();
    });
}


// --------------------------------------------------
// QR CODE PAGE
// --------------------------------------------------
function showQRCode(joinURL, code) {
    show("screen_qr");

    new QRious({
        element: document.getElementById("qrCanvas"),
        value: joinURL,       // 🔥 global join link
        size: 260
    });

    document.getElementById("qrRoomCode").innerText = `Room Code: ${code}`;
}

function setupLobbyUI() {
    const lobby = document.getElementById("playerLobby");
    lobby.innerHTML = "";

    for (let i = 0; i < 5; i++) {
        const slot = document.createElement("div");
        slot.className = "playerSlot";
        slot.id = `slot_${i}`;

        slot.innerHTML = `
            <div class="waitingText">Waiting...</div>
        `;

        lobby.appendChild(slot);
    }
}

function updateLobbyUI() {
    players.forEach((p, i) => {
        const slot = document.getElementById(`slot_${i}`);

        if (!p) {
            slot.innerHTML = `<div class="waitingText">Waiting...</div>`;
        } else {
            slot.innerHTML = `
                <div class="playerEmoji">${p.emoji}</div>
                <div class="playerName">${p.name}</div>
            `;
        }
    });
}

function addNewPlayer(name) {
    // Find empty slot
    const idx = players.findIndex(p => p === null);
    if (idx === -1) return;

    players[idx] = {
        name,
        emoji: randomEmoji()
    };

    updateLobbyUI();
}
