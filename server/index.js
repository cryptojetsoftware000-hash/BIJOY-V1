const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");
const os = require("os");

const PORT = process.env.PORT || 3000;
const MAX_MESSAGE_LENGTH = 1000;

const app = express();
app.use(cors());
app.use(express.json());

const httpServer = http.createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
  transports: ["websocket", "polling"],
});

const users = new Map();

function getLocalIps() {
  const interfaces = os.networkInterfaces();
  const ips = [];

  Object.values(interfaces).forEach((items) => {
    (items || []).forEach((item) => {
      if (item.family === "IPv4" && !item.internal) {
        ips.push(item.address);
      }
    });
  });

  return ips;
}

function cleanText(value, fallback = "") {
  return String(value ?? fallback).trim().slice(0, MAX_MESSAGE_LENGTH);
}

function userList() {
  return Array.from(users.values()).map((user) => ({
    id: user.id,
    username: user.username,
  }));
}

function sendSystemMessage(text) {
  io.emit("system_message", {
    id: `system-${Date.now()}`,
    text,
    timestamp: new Date().toISOString(),
  });
}

app.get("/", (_req, res) => {
  res.json({
    app: "BIJOY-V1 Chat Server",
    status: "running",
    port: PORT,
    users: users.size,
    localIps: getLocalIps(),
  });
});

app.get("/health", (_req, res) => {
  res.json({ ok: true, users: users.size, time: new Date().toISOString() });
});

io.on("connection", (socket) => {
  console.log(`Client connected: ${socket.id}`);

  socket.on("join", (payload = {}) => {
    const username = cleanText(payload.username, "Guest") || "Guest";

    socket.data.username = username;
    users.set(socket.id, {
      id: socket.id,
      username,
    });

    socket.emit("joined", {
      id: socket.id,
      username,
      timestamp: new Date().toISOString(),
    });

    io.emit("users", userList());
    sendSystemMessage(`${username} joined the chat`);

    console.log(`${username} joined (${socket.id})`);
  });

  socket.on("chat_message", (payload = {}) => {
    const username = socket.data.username || cleanText(payload.username, "Guest") || "Guest";
    const text = cleanText(payload.text);

    if (!text) return;

    const message = {
      id: `${socket.id}-${Date.now()}`,
      senderId: socket.id,
      username,
      text,
      timestamp: new Date().toISOString(),
    };

    io.emit("chat_message", message);
    console.log(`[${username}] ${text}`);
  });

  socket.on("typing", (payload = {}) => {
    const username = socket.data.username || cleanText(payload.username, "Guest") || "Guest";
    socket.broadcast.emit("typing", {
      username,
      isTyping: Boolean(payload.isTyping),
    });
  });

  socket.on("disconnect", () => {
    const user = users.get(socket.id);
    users.delete(socket.id);

    if (user) {
      sendSystemMessage(`${user.username} left the chat`);
      io.emit("users", userList());
      console.log(`${user.username} left (${socket.id})`);
    } else {
      console.log(`Client disconnected: ${socket.id}`);
    }
  });
});

httpServer.listen(PORT, "0.0.0.0", () => {
  const ips = getLocalIps();

  console.log("======================================");
  console.log("BIJOY-V1 Chat Server running");
  console.log(`Port: ${PORT}`);
  console.log("Open from phone using one of these URLs:");
  ips.forEach((ip) => console.log(`http://${ip}:${PORT}`));
  console.log("======================================");
});
