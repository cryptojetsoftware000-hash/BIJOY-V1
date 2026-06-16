# BIJOY-V1 Install Guide বাংলা

## 1) PC তে Node.js install করো

Node.js না থাকলে install করো।

তারপর:

```bash
cd server
npm install
npm start
```

Server চালু হলে terminal এ IP দেখাবে, যেমন:

```text
http://192.168.1.100:3000
```

এই URL টা app এ দিতে হবে।

---

## 2) Flutter app চালানো

Flutter install করা থাকলে:

```bash
cd flutter_app
flutter create . --platforms=android
flutter pub get
flutter run
```

---

## 3) Mobile + PC same WiFi

খুব important:

- PC এবং mobile একই WiFi তে থাকবে
- App এ `localhost` লিখবে না
- App এ PC এর IP লিখবে, যেমন `http://192.168.1.100:3000`

---

## 4) কাজ না করলে

### Problem: App connect হচ্ছে না

Fix:
- Windows Firewall এ Node.js allow করো
- PC এবং phone same WiFi কিনা check করো
- IP ঠিক আছে কিনা check করো
- Server চলছে কিনা check করো

Browser থেকে phone এ open করে দেখো:

```text
http://PC_IP:3000/health
```

Example:

```text
http://192.168.1.100:3000/health
```

যদি `{ ok: true }` আসে, server ঠিক আছে।
