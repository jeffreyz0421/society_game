//
//  main.js — FINAL POLISHED VERSION
//

let socket = null;
let playerID = null;
let roomCode = null;
let isHost = false;

const EMOJIS = ["😎","🤠","🙂","🥸","🤓","😇","😁","🤩"];
function randomEmoji() {
    return EMOJIS[Math.floor(Math.random() * EMOJIS.length)];
}

let players = [null, null, null, null, null];

// 🌍 BACKEND URL
const BACKEND_HTTP = "https://society-game-backend.onrender.com";
const BACKEND_WS   = "wss://society-game-backend.onrender.com";

// --------------------------------------------------
// UI HELPERS
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

        // Player enters lobby screen
        show("screen_waiting");
        document.getElementById("waitingRoomCode").innerText = roomCode;

        openSocket();
    })
    .catch(err => console.error("JOIN ERR:", err));
}

// --------------------------------------------------
// OPEN WEBSOCKET
// --------------------------------------------------
function openSocket() {
    socket = new WebSocket(`${BACKEND_WS}/ws/${roomCode}/${playerID}`);

    socket.onopen = () => {
        console.log("WS connected!");
        // 🧘 Players stay on waiting lobby, host stays on QR screen
    };

    socket.onmessage = (msg) => {
        const data = JSON.parse(msg.data);
        console.log("WS MSG:", data);

        switch (data.type) {

            case "player_joined":
                addNewPlayer(data.name);
                break;

            case "start_game":
                // Everyone moves to role selection
                show("screen_role");
                break;
                
            case "nomination":
                console.log(`${data.player} nominated ${data.role}`);
                break;

            case "roles_available":
                renderRoles(data.roles);
                break;

            case "chat":
                addChatMessage(data.from, data.text);
                addChatMessageToHistory(data.from, data.text);
                break;


            case "start_countdown":
                startCountdown();
                break;
                
            case "nomination":
                console.log(`${data.player} nominated for ${data.role}`);
                break;


            case "start_voting":
                show("screen_voting");
                renderVoting(data.options);
                break;
        }
    };
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
// HOST FLOW
// --------------------------------------------------
let hostName = null;
let hostEmoji = null;

function finishHostSetup() {
    hostName = document.getElementById("hostNameInput").value.trim();
    if (!hostName) return alert("Enter your name!");

    hostEmoji = randomEmoji();

    fetch(`${BACKEND_HTTP}/create`, { method: "POST" })
        .then(r => r.json())
        .then(data => {
            roomCode = data.code;
            isHost = true;

            showQRCode(data.joinURL, data.code);
            setupLobbyUI();
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

        players[0] = { name: hostName, emoji: hostEmoji };
        updateLobbyUI();
    });
}

// --------------------------------------------------
// QR SCREEN
// --------------------------------------------------
function showQRCode(joinURL, code) {
    show("screen_qr");

    new QRious({
        element: document.getElementById("qrCanvas"),
        value: joinURL,
        size: 260
    });

    document.getElementById("qrRoomCode").innerText = `Room Code: ${code}`;
    document.getElementById("startGameBtn").classList.remove("hidden");
}

// --------------------------------------------------
// LOBBY PLAYER SYSTEM
// --------------------------------------------------
function setupLobbyUI() {
    const lobby = document.getElementById("playerLobby");
    lobby.innerHTML = "";

    for (let i = 0; i < 5; i++) {
        lobby.innerHTML += `
            <div class="playerSlot" id="slot_${i}">
                <div class="waitingText">Waiting...</div>
            </div>
        `;
    }
}

function updateLobbyUI() {
    players.forEach((p, i) => {
        const slot = document.getElementById(`slot_${i}`);
        if (!slot) return;

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
    const idx = players.findIndex(p => p === null);
    if (idx === -1) return;

    players[idx] = { name, emoji: randomEmoji() };
    updateLobbyUI();
    updateRoundTable();   // ← ADD THIS
}
function updateRoundTable() {
    for (let i = 0; i < 5; i++) {
        const seat = document.getElementById(`seat${i}`);
        const p = players[i];

        if (!seat) continue;
        if (!p) {
            seat.innerHTML = "<div style='margin-top:30px;color:#aaa;font-size:18px;'>Waiting...</div>";
        } else {
            seat.innerHTML = `
                <div style="font-size:40px">${p.emoji}</div>
                <div style="font-size:18px;margin-top:4px;font-weight:600;">${p.name}</div>
            `;
        }
    }
}


// --------------------------------------------------
// START GAME (host only)
// --------------------------------------------------
function startGame() {
    socket.send(JSON.stringify({
        type: "start_countdown"
    }));
}

function openChat() {
    show("screen_chat");
}

function sendChat2() {
    const input = document.getElementById("chatInput2");
    const text = input.value.trim();
    if (!text) return;

    socket.send(JSON.stringify({ type: "chat", text }));
    input.value = "";
}

function addChatMessageToHistory(from, text) {
    const box = document.getElementById("chatHistory");
    if (!box) return;

    const el = document.createElement("div");
    el.className = "chatBubble";
    el.innerHTML = `<strong>${from}:</strong> ${text}`;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
}
function startCountdown() {
    show("screen_countdown");

    let t = 5;
    document.getElementById("countdownNumber").innerText = t;

    const interval = setInterval(() => {
        t--;
        if (t > 0) {
            document.getElementById("countdownNumber").innerText = t;
        } else if (t === 0) {
            document.getElementById("countdownNumber").innerText = "🎤";
            document.getElementById("countdownMessage").innerText = "Prepare to debate!";
        } else {
            clearInterval(interval);

            // 🔥 SHOW NOMINATION SCREEN
            show("screen_nomination");

            // 🔥 LOAD NOMINATION BUTTONS
            renderNominationRoles();
        }
    }, 1000);
}

function renderNominationRoles() {
    const roles = [
        "President (+200 points, <span style='font-size:16px'>if got the position</span>)",
        "Chief Justice (+200 points, <span style='font-size:16px'>if got the position</span>)",
        "Department of Education (+100 points, <span style='font-size:16px'>if got the position</span>)",
        "Department of Labor (+100 points, <span style='font-size:16px'>if got the position</span>)",
        "Department of Construction (+100 points, <span style='font-size:16px'>if got the position</span>)"
    ];

    const container = document.getElementById("nominationList");
    container.innerHTML = "";

    roles.forEach(role => {
        const btn = document.createElement("button");
        btn.className = "roleButton";
        btn.innerHTML = role;  // IMPORTANT: innerHTML instead of innerText

        btn.onclick = () => {
            socket.send(JSON.stringify({
                type: "nomination",
                role
            }));

            // save choice for UI
            window.nominationChoice = role;

            // update campaigning screen text
            const desired = document.getElementById("campaignDesiredRole");
            if (desired) desired.innerHTML = "Desired Position: " + role;

            show("screen_campaigning");
        };

        container.appendChild(btn);
    });
}
