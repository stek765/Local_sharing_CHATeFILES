#!/bin/bash

USERNAME="$1"
BASE_DIR="$(pwd)/.."
CLIENTS_DIR="$BASE_DIR/certs/clients"
PACKAGES_DIR="$BASE_DIR/packages"
USERS_FILE="$BASE_DIR/users.txt"

if [ -z "$USERNAME" ]; then
  echo "❌ Inserisci un nome utente da rimuovere"
  echo "👉 Esempio: ./remove_user.sh stefano"
  exit 1
fi

echo "⚠️ Rimozione dell'utente: $USERNAME..."

# === Rimuovi certificati e chiavi ===
rm -f "$CLIENTS_DIR/$USERNAME.key"
rm -f "$CLIENTS_DIR/$USERNAME.crt"
rm -f "$CLIENTS_DIR/$USERNAME.p12"
rm -rf "$PACKAGES_DIR/$USERNAME"

echo "🧹 File in $CLIENTS_DIR e $PACKAGES_DIR rimossi"

# === Rimuovi dal file users.txt ===
if [ -f "$USERS_FILE" ]; then
  grep -v "^$USERNAME\$" "$USERS_FILE" > "$USERS_FILE.tmp" && mv "$USERS_FILE.tmp" "$USERS_FILE"
  echo "✏️ Rimosso $USERNAME da $(basename "$USERS_FILE")"
fi

# === Rimuovi certificato e chiave dal portachiavi login ===
security delete-certificate -c "$USERNAME" ~/Library/Keychains/login.keychain-db 2>/dev/null && \
  echo "🗑️ Certificato $USERNAME rimosso dal portachiavi login"

security delete-identity -s "$USERNAME" ~/Library/Keychains/login.keychain-db 2>/dev/null && \
  echo "🗑️ Chiave privata $USERNAME rimossa dal portachiavi login"

echo "✅ Utente $USERNAME rimosso con successo"