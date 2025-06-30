#!/bin/bash

CA_DIR="../certs/myCA"
CERTS_DIR="../certs"
mkdir -p "$CA_DIR" "$CERTS_DIR"

CA_KEY="$CA_DIR/ca.key"
CA_CERT="$CA_DIR/ca.crt"

SERVER_KEY="$CERTS_DIR/myServer/server.key"
SERVER_CSR="$CERTS_DIR/myServer/server.csr"
SERVER_CERT="$CERTS_DIR/myServer/server.crt"

# === Controlla se esistono già ===
if [ -f "$CA_KEY" ] || [ -f "$CA_CERT" ]; then
  echo "⚠️  CA già esistente in $CA_DIR"
  read -p "❓ Vuoi sovrascrivere la CA? [y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "⏹️  Annullato"
    exit 1
  fi
  rm -f "$CA_KEY" "$CA_CERT" "$SERVER_KEY" "$SERVER_CSR" "$SERVER_CERT"
fi

# === Crea la chiave privata della CA ===
openssl genrsa -out "$CA_KEY" 4096

# === Crea il certificato della CA (autosigned) ===
openssl req -x509 -new -nodes -key "$CA_KEY" \
  -sha256 -days 3650 \
  -out "$CA_CERT" \
  -subj "/C=IT/ST=Italy/L=Verona/O=Stek/OU=CA/CN=LocalCA"

echo "✅ CA inizializzata in $CA_DIR"

# === Genera chiave privata del server ===
openssl genrsa -out "$SERVER_KEY" 2048

# === Genera richiesta di firma (CSR) per il server ===
openssl req -new -key "$SERVER_KEY" \
  -out "$SERVER_CSR" \
  -subj "/C=IT/ST=Italy/L=Verona/O=Stek/OU=Server/CN=localhost"

# === Firma la richiesta del server con la CA ===
openssl x509 -req -in "$SERVER_CSR" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$SERVER_CERT" -days 825 -sha256

echo "✅ Certificato server firmato e generato in $CERTS_DIR"