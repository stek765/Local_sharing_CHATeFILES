# 🔐 Local Sharing - Secure LAN Communication

**Local Sharing** is a lightweight, local web application to **securely exchange messages and files within your LAN**.

No servers on the Internet. No user accounts. Just fast, private, local communication with real client certificate authentication.

---

## 🧠 Why this?

Most LAN tools are either insecure or require passwords.  
**Local Sharing** uses your own **Certificate Authority (CA)** and **client certificates** to authenticate users **automatically**, ensuring:

- ✅ Only approved users can access the app
- 🔒 All messages and file transfers are encrypted (HTTPS)
- 👁️ No credentials are sent over the network

---

## ⚙️ How it works

1. A server runs locally (`server.py`) with HTTPS and certificate-based authentication
2. Clients open the page from any device in the LAN (e.g. https://192.168.1.42:5010)
3. The browser presents a valid **client certificate** to log in
4. Each message and upload is stored **only locally**

---

## 🛡️ Security model

- 🔐 Uses **TLS with mutual authentication** (client+server certificates)
- 🧾 You generate your own **CA** (Certificate Authority)
- 👤 Each user has a signed **certificate and private key**
- 🧱 Unauthorized clients are **rejected at connection**

---

## 🚀 Getting started

1. **Generate your CA** (once)
   ```bash
   ./init_ca.sh
   ```

2. **Add a new user** (e.g. `mario`)
   ```bash
   ./add_user.sh mario
   ```

   This creates:
   - `clients/mario.crt` + `mario.key`
   - A package in `packages/mario/` with everything needed
   - Adds `mario` to the `users.txt` whitelist


3. **Run the server**
   ```bash
   python3 server.py
   ```

4. **Install the user's certificate**  
   On macOS:
   ```bash
   ./setup_client.sh mario
   ```



5. **Open the app**
   Open the local server URL in your browser, e.g.  
   https://localhost:5010 or https://your-ip:5010

---

## ❌ Remove a user

To fully remove a user (files, portachiain, whitelist):
```bash
./remove_user.sh mario
```

---

## 📁 Project structure

```
Local_sharing/
├── certs/            # Your CA and server certificates
├── clients/          # User certificates and private keys
├── packages/         # Ready-to-send folders for each user
├── templates/        # HTML files
├── uploads/          # Uploaded files
├── chat.txt          # Stored messages
├── users.txt         # List of allowed usernames
├── server.py         # HTTPS server
├── add_user.sh       # Adds a new user
├── remove_user.sh    # Removes a user
├── setup_client.sh   # Installs a user's cert in system
```

---

## ✅ Requirements

- Python 3
- OpenSSL
- macOS (for certificate automation)
- Local network access

---

## 🧠 Idea behind the project

Designed for **teams, families, or developers** sharing a local Wi-Fi or LAN,  
without relying on any third-party services — everything stays **local and encrypted**.

---
