# 🔐 Local Sharing CHAT&FILES - Secure LAN Communication

**Local Sharing** is a secure, local-first web application for exchanging files and messages over your LAN — with no accounts, no passwords, and no internet servers.

It uses **TLS mutual authentication** and **digital signatures** to ensure confidentiality, authenticity, and integrity.

---

## 🛡️ Security Features

### ✅ Mutual TLS Authentication
- Only authorized clients with a valid certificate can access the system
- Each user has their own private key and certificate, signed by a local CA

### ✅ Confidentiality
- All data (messages, uploads) is transmitted over HTTPS (TLS)
- Certificates are used instead of passwords — no credentials sent over the network

### ✅ Integrity
- Uploaded files are signed server-side using the server's private key
- A `.sig` file is created for each file, allowing users to verify authenticity later

---

## 🚀 Setup Instructions

You can set up everything in under 5 minutes.

### 1. Clone the repository and enter the folder
```bash
git clone https://github.com/stek765/Local_sharing_CHATeFILES.git
cd Local_sharing_CHATeFILES
```

### 2. Generate your Certificate Authority (CA)
This will create:
- Your root `ca.crt` and `ca.key`
- A signed server certificate and key

```bash
./init_ca.sh
```

### 3. Add a new user (e.g., `mario`)
This creates a certificate, key, and a ready-to-install package:
```bash
./add_user.sh mario
```

You will get:
- `clients/mario.crt` and `mario.key`
- A user package in `packages/mario/` for easy import
- `users.txt` updated with the new username

### 4. Start the secure server
```bash
python3 server.py
```

### 5. Install the user certificate (macOS) and auto-load the page
```bash
./setup_client.sh mario
```

This installs the user's credentials into macOS Keychain for Safari/Chrome.


### 6. Open the application
From any device in the LAN with a valid certificate:
```
https://your-local-ip:5010
```

---

## ❌ Removing a User

To fully remove a user (certs + permissions):
```bash
./remove_user.sh <name> (es: mario)
```

---

## 📁 Project Structure

```
Local_sharing_CHATeFILES/
├── certs/            # CA, client, and server certificates
    ├── clients/        
    ├── myCA/
    ├── myServer/
├── packages/         # Distributable client packages
├── scripts/          # All the main scripts of the app
├── serverStuff/
    ├── templates/        # HTML interface (chat + file preview)
    ├── uploads/          # Signed uploaded files
    ├── chat.txt          # Stored messages
├── server.py         # Flask-based HTTPS server
├── users.txt         # Authorized usernames
```

---

## 💡 Concept

Designed for **developers, families, or internal teams** who share a Wi-Fi or LAN and want:

- Simple, secure local communication
- Zero dependency on third-party services
- Private data exchange with verified identities

Whether you're exchanging sensitive files or just chatting on your LAN, **Local Sharing** gives you a trusted, encrypted, and verified space — offline.

---

## ✅ Requirements

- Python 3
- OpenSSL
- macOS (for certificate automation)
- LAN/Wi-Fi environment
