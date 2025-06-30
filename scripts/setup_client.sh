#!/bin/bash

# Questo script importa un certificato client e la sua chiave privata nel portachiavi di macOS
# e apre Safari per la connessione al server locale.

USERNAME="$1"
BASE_DIR="$(pwd)/.."
CLIENTS_DIR="$BASE_DIR/certs/clients"
CA_CERT="$BASE_DIR/certs/myCA/ca.crt"
CERT_FILE="$CLIENTS_DIR/$USERNAME.crt"
KEY_FILE="$CLIENTS_DIR/$USERNAME.key"

# === Controlli iniziali ===
if [ -z "$USERNAME" ]; then
  echo "❌ Inserisci un nome utente"
  echo "👉 Esempio: ./setup_client.sh stefano"
  exit 1
fi

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ] || [ ! -f "$CA_CERT" ]; then
  echo "❌ File mancanti. Assicurati che esistano:"
  echo "   - $CERT_FILE"
  echo "   - $KEY_FILE"
  echo "   - $CA_CERT"
  exit 1
fi

# === Controlla se certificato utente è già nel portachiavi ===
IS_IMPORTED=$(security find-certificate -c "$USERNAME" ~/Library/Keychains/login.keychain-db 2>/dev/null)

if [ -n "$IS_IMPORTED" ]; then
  echo "ℹ️  Certificato già presente. Salto importazione."
else
  # === Importa certificato ===
  security import "$CERT_FILE" -k ~/Library/Keychains/login.keychain-db -T /Applications/Safari.app && \
    echo "✅ Certificato $USERNAME.crt importato" || \
    echo "❌ Errore nell'importazione del certificato $USERNAME.crt"

  # === Importa chiave privata ===
  security import "$KEY_FILE" -k ~/Library/Keychains/login.keychain-db -T /Applications/Safari.app && \
    echo "✅ Chiave privata $USERNAME.key importata" || \
    echo "❌ Errore nell'importazione della chiave privata"
fi

# === Verifica se la CA è già trusted ===
CA_HASH=$(openssl x509 -noout -in "$CA_CERT" -fingerprint -sha1 | cut -d= -f2)
IS_CA_TRUSTED=$(security find-certificate -a -Z /Library/Keychains/System.keychain | grep -i "$CA_HASH")

if [ -n "$IS_CA_TRUSTED" ]; then
  echo "ℹ️  CA già presente come trusted. Salto aggiunta."
else
  # === Aggiungi CA come trusted root ===
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_CERT" && \
    echo "✅ CA aggiunta con fiducia al sistema" || \
    echo "⚠️  La CA potrebbe essere già fidata o servono permessi admin"
fi

# === Apri Safari ===
echo "🌐 Apro https://localhost:5010/ in Safari..."
open -a Safari "https://localhost:5010/"