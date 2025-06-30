#!/bin/bash

USERNAME="$1"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"  # va nella cartella superiore rispetto a /scripts
CLIENTS_DIR="$BASE_DIR/certs/clients"
CERTS_DIR="$BASE_DIR/certs/myCA"
PKG_DIR="$BASE_DIR/packages/$USERNAME"
CA_CERT="$CERTS_DIR/ca.crt"
CA_KEY="$CERTS_DIR/ca.key"

# === Controlli iniziali ===
if [ -z "$USERNAME" ]; then
  echo "❌ Inserisci un nome utente"
  echo "👉 Esempio: ./add_user.sh mario"
  exit 1
fi

if [ ! -f "$CA_CERT" ] || [ ! -f "$CA_KEY" ]; then
  echo "❌ CA non trovata in $CERTS_DIR"
  exit 1
fi

# === Crea chiave e richiesta di firma (CSR) ===
openssl genrsa -out "$CLIENTS_DIR/$USERNAME.key" 2048
openssl req -new -key "$CLIENTS_DIR/$USERNAME.key" \
  -out "$CLIENTS_DIR/$USERNAME.csr" \
  -subj "/C=IT/ST=Italy/L=Verona/O=Stek/OU=client/CN=$USERNAME"

# === Firma la CSR con la CA ===
openssl x509 -req -in "$CLIENTS_DIR/$USERNAME.csr" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$CLIENTS_DIR/$USERNAME.crt" -days 365 -sha256

# === Aggiungi utente al file autorizzati ===
echo "$USERNAME" >> "$BASE_DIR/users.txt"

# === Prepara pacchetto utente ===
mkdir -p "$PKG_DIR"
cp "$CLIENTS_DIR/$USERNAME.crt" "$PKG_DIR/"
cp "$CLIENTS_DIR/$USERNAME.key" "$PKG_DIR/"
cp "$CA_CERT" "$PKG_DIR/"

# === Crea README.txt ===
cat > "$PKG_DIR/README.txt" <<EOF
✅ Welcome, $USERNAME!

You've received a secure authentication package.

It contains:
- $USERNAME.crt : Your client certificate
- $USERNAME.key : Your private key
- ca.crt        : The CA certificate to authenticate the server
- README.txt    : This file

👉 To connect securely, ask the administrator for help with installation or use the provided setup tools if available.

🧠 Need help? Contact your system administrator.
EOF

# === Cleanup ===
rm "$CLIENTS_DIR/$USERNAME.csr"

echo "✅ User $USERNAME added and package created in packages/$USERNAME/"