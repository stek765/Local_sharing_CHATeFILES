import sys
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography import x509

def verify_signature(file_path, sig_path, cert_path):
    # 1. Carica il contenuto del file
    with open(file_path, 'rb') as f:
        file_data = f.read()

    # 2. Carica la firma
    with open(sig_path, 'rb') as f:
        signature = f.read()

    # 3. Carica il certificato in formato PEM
    with open(cert_path, 'rb') as f:
        cert_data = f.read()
        cert = x509.load_pem_x509_certificate(cert_data)
        public_key = cert.public_key()

    # 4. Verifica la firma
    try:
        public_key.verify(
            signature,
            file_data,
            padding.PKCS1v15(),
            hashes.SHA256()
        )
        print("✅ Firma valida: il file è integro e autentico.")
    except Exception as e:
        print("❌ Firma NON valida!")
        print(f"   Dettagli: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Uso: python3 integrity_check.py <file> <firma.sig> <certificato.crt>")
        sys.exit(1)

    file_path = sys.argv[1]
    sig_path = sys.argv[2]
    cert_path = sys.argv[3]

    verify_signature(file_path, sig_path, cert_path)