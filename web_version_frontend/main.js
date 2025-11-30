//
//  main.js
//  Society Game
//
//  Created by Jeffrey Zheng on 11/29/25.
//

let socket = null;
let playerID = null;
let roomCode = null;

// helper
function show(id) {
    document.querySelectorAll(".screen").forEach(s => s.classList.add("hidden"));
    document.getElementById(id).classList.remove("hidden");
}

function joinRoom() {
    roomCode = document.getElementById("roomCodeInput").value;
    const name = document.getElementById("playerNameInput").value;

    // join via REST
    fetch("http://localhost:8080/join", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code: roomCode, name })
    })
    .then(r => r.json())
    .then(data => {
        playerID = data.playerID;
        openSocket();
    });
}

function openSocket() {
    socket = new WebSocket(`ws://localhost:8080/ws/${roomCode}/${playerID}`);

    socket.onopen = () => {
        console.log("WS connected");
        show("screen_role");
    };

    socket.onmessage = (msg) => {
        const data = JSON.parse(msg.data);

        if (data.type === "roles_available") {
            renderRoles(data.roles);
        }
        if (data.type === "chat") {
            addChatMessage(data.from, data.text);
        }
        if (data.type === "start_campaign") {
            show("screen_campaigning");
        }
        if (data.type === "start_voting") {
            show("screen_voting");
            renderVoting(data.options);
        }
    };
}

function renderRoles(roles) {
    const container = document.getElementById("roleList");
    container.innerHTML = "";

    roles.forEach(r => {
        const btn = document.createElement("button");
        btn.innerText = r;
        btn.onclick = () => {
            socket.send(JSON.stringify({ type: "select_role", role: r }));
        };
        container.appendChild(btn);
    });
}

function sendChat() {
    const text = document.getElementById("chatInput").value;
    socket.send(JSON.stringify({ type: "chat", text }));
    document.getElementById("chatInput").value = "";
}

function addChatMessage(from, text) {
    const box = document.getElementById("chatBox");
    const el = document.createElement("div");
    el.innerText = `${from}: ${text}`;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
}

function renderVoting(options) {
    const container = document.getElementById("voteOptions");
    container.innerHTML = "";

    options.forEach(role => {
        const btn = document.createElement("button");
        btn.innerText = `Vote: ${role}`;
        btn.onclick = () =>
            socket.send(JSON.stringify({ type: "vote", role }));
        container.appendChild(btn);
    });
}

function hostRoom() {
    fetch("http://YOUR-IP-ADDRESS:8080/create", {
        method: "POST"
    })
    .then(r => r.json())
    .then(data => {
        console.log("Room created:", data);
        showQRCode(data.joinURL, data.code);
    })
    .catch(err => console.error("HostRoom error:", err));
}

function showQRCode(joinURL, code) {
    show("screen_qr");

    new QRious({
        element: document.getElementById("qrCanvas"),
        value: joinURL,
        size: 250
    });

    document.getElementById("qrRoomCode").innerText = `Room Code: ${code}`;
}

