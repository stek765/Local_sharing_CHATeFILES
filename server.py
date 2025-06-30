from flask import Flask, request, render_template, send_from_directory, redirect, url_for, session
import os
import subprocess
from datetime import datetime
from werkzeug.utils import secure_filename
from flask import send_file

# === Funzione per recuperare l'SSID Wi-Fi del Mac ===
def get_ssid():
    try:
        # Usa networksetup per trovare l'interfaccia Wi-Fi (di solito "en0")
        result = subprocess.run(["networksetup", "-listallhardwareports"],
                                capture_output=True, text=True)
        if result.returncode != 0:
            return None

        # Cerca la riga con "Wi-Fi" e trova il nome del device
        lines = result.stdout.splitlines()
        for i in range(len(lines)):
            if "Wi-Fi" in lines[i] or "AirPort" in lines[i]:
                device_line = lines[i + 1]
                if "Device" in device_line:
                    device = device_line.split(": ")[1].strip()

                    # Recupera l'SSID dal device
                    ssid_result = subprocess.run(["ipconfig", "getsummary", device],
                                                 capture_output=True, text=True)
                    for l in ssid_result.stdout.splitlines():
                        if " SSID" in l:
                            return l.split(": ")[1].strip()
    except Exception as e:
        print(f"[!] Errore nel recupero SSID: {e}")
        return None
    return None

# === Percorsi di base ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "serverStuff/uploads")
CHAT_LOG = os.path.join(BASE_DIR, "serverStuff/chat.txt")
USERS_FILE = os.path.join(BASE_DIR, "users.txt")
TEMPLATES_DIR = os.path.join(BASE_DIR, "serverStuff/templates")
SERVER_KEY = os.path.join(BASE_DIR, "certs/myServer/server.key")

# === Flask setup ===
app = Flask(__name__, template_folder=TEMPLATES_DIR)
app.secret_key = 'supersegreto'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# === Pagina principale con autenticazione del certificato ===
@app.route("/", methods=['GET', 'POST'])
def index():
    # Recupera il certificato client dalla connessione TLS
    cert_pem = request.environ.get('SSL_CLIENT_CERT')
    if not cert_pem:
        return "Certificato client mancante o non fornito correttamente", 403

    try:
        # Estrai il CN (Common Name) dal certificato X.509
        from OpenSSL import crypto
        x509 = crypto.load_certificate(crypto.FILETYPE_PEM, cert_pem)
        cn = x509.get_subject().CN
    except Exception as e:
        return f"Errore nella lettura del certificato: {e}", 500

    # Salva l'utente in sessione se non già autenticato
    if session.get('username') != cn:
        session['username'] = cn
        print(f"🔐 Autenticato: {cn}")

    # Controlla se l'utente è autorizzato (presente nel file users.txt)
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as f:
            allowed_users = [line.strip() for line in f.readlines()]
        if cn not in allowed_users:
            return f"Accesso negato: {cn} non è autorizzato", 403
    else:
        return "File users.txt non trovato", 500

    # Recupera i file caricati e i messaggi della chat
    files = os.listdir(UPLOAD_FOLDER)
    messages = []
    if os.path.exists(CHAT_LOG):
        with open(CHAT_LOG, 'r') as f:
            messages = f.readlines()

    ssid = get_ssid()
    return render_template("index.html", files=files, messages=messages,
                           username=session['username'], ssid=ssid)

# === Logout manuale ===
@app.route("/logout")
def logout():
    session.pop('username', None)
    return redirect(url_for('index'))

# === Invia un messaggio nella chat ===
@app.route("/send", methods=["POST"])
def send():
    if 'username' not in session:
        return redirect(url_for('index'))

    msg = request.form['message']
    now = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    with open(CHAT_LOG, 'a') as f:
        f.write(f"[{now}] {session['username']}: {msg}\n")
    return '', 204

# === Upload di un file con firma digitale ===
@app.route("/upload", methods=['POST'])
def upload():
    if 'username' not in session:
        return redirect(url_for('index'))

    file = request.files['file']
    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        # Firma il file usando la chiave privata del server
        signature_path = filepath + '.sig'
        with open(filepath, 'rb') as f:
            subprocess.run([
                "openssl", "dgst", "-sha256",
                "-sign", SERVER_KEY,
                "-out", signature_path,
                "-"
            ], input=f.read())

    return redirect(url_for('index'))

# === Download di un file ===
@app.route('/files/<filename>')
def serve_file(filename):
    if 'username' not in session:
        return redirect(url_for('index'))
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    if os.path.exists(file_path):
        return send_file(file_path, as_attachment=True)
    else:
        return "File non trovato", 404

# === Recupera i messaggi per aggiornare la chat in tempo reale ===
@app.route("/messages")
def get_messages():
    if os.path.exists(CHAT_LOG):
        with open(CHAT_LOG, 'r') as f:
            return "<br>".join(f.readlines())
    return ""

# === Cancella la chat ===
@app.route("/clear", methods=["POST"])
def clear_chat():
    open(CHAT_LOG, 'w').close()
    return redirect(url_for('index'))

# === Cancella tutti i file caricati ===
@app.route("/clear_files", methods=["POST"])
def clear_files():
    for filename in os.listdir(UPLOAD_FOLDER):
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        if os.path.isfile(file_path):
            os.remove(file_path)
    return redirect(url_for('index'))

# === Server HTTPS con richiesta di certificato client ===
if __name__ == '__main__':
    from werkzeug.serving import WSGIRequestHandler

    # Custom handler per estrarre il certificato client nella request
    class PeerCertWSGIRequestHandler(WSGIRequestHandler):
        def make_environ(self):
            environ = super().make_environ()
            if self.connection and hasattr(self.connection, 'getpeercert'):
                cert = self.connection.getpeercert(True)
                if cert:
                    from OpenSSL import crypto
                    x509 = crypto.load_certificate(crypto.FILETYPE_ASN1, cert)
                    pem_cert = crypto.dump_certificate(crypto.FILETYPE_PEM, x509).decode('utf-8')
                    environ['SSL_CLIENT_CERT'] = pem_cert
            return environ

    # Setup TLS: certificato server, chiave e CA
    import ssl
    SERVER_CERT = os.path.join(BASE_DIR, "certs/myServer/server.crt")
    SERVER_KEY = os.path.join(BASE_DIR, "certs/myServer/server.key")
    CA_CERT = os.path.join(BASE_DIR, "certs/myCA/ca.crt")

    # Richiede certificato client (mutual TLS)
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(certfile=SERVER_CERT, keyfile=SERVER_KEY)
    context.load_verify_locations(cafile=CA_CERT)
    context.verify_mode = ssl.CERT_REQUIRED

    # Avvia il server Flask su HTTPS con autenticazione a 2 vie
    app.run(
        host='0.0.0.0',
        port=5010,
        ssl_context=context,
        request_handler=PeerCertWSGIRequestHandler
    )