# BIJOY-V1 — Chat Pro (Flutter + WiFi LAN Chat)

BIJOY-V1 is a **local WiFi chatting app**.  
It works inside the same WiFi/router network. Internet is not required after setup.

## Features

- Real-time chat using Socket.io
- Same WiFi / LAN based messaging
- Username system
- Online users count/list
- Modern Flutter chat UI
- Auto reconnect
- Node.js local server
- Android ready starter code

## Project Structure

```text
BIJOY-V1/
├── server/
│   ├── index.js
│   └── package.json
├── flutter_app/
│   ├── lib/main.dart
│   └── pubspec.yaml
├── docs/
│   ├── INSTALL_BANGLA.md
│   └── ANDROID_PERMISSION.md
└── README.md
```

---

## 1) Run Local Server

Install Node.js first.

```bash
cd server
npm install
npm start
```

You should see:

```text
BIJOY-V1 Chat Server running
Port: 3000
```

Now find your computer IP address.

### Windows

```bash
ipconfig
```

Look for:

```text
IPv4 Address . . . . . . . . . . : 192.168.x.x
```

Example server URL:

```text
http://192.168.1.100:3000
```

---

## 2) Run Flutter App

Install Flutter first.

```bash
cd flutter_app
flutter create . --platforms=android
flutter pub get
flutter run
```

When the app opens:
1. Enter your name
2. Enter server URL, example: `http://192.168.1.100:3000`
3. Tap **Connect**
4. Start chatting

---

## Important

- Mobile and PC must be connected to the **same WiFi**
- Do **not** use `localhost` in mobile app
- Use PC LAN IP like `http://192.168.1.100:3000`
- Allow port `3000` in Windows Firewall if connection fails
