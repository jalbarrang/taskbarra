#!/usr/bin/env bash
set -euo pipefail

IDENTITY="Taskbarra Local"
KEYCHAIN="$(security default-keychain -d user | sed -e 's/^[[:space:]]*"//' -e 's/"[[:space:]]*$//')"

if security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -F "\"$IDENTITY\"" >/dev/null; then
  echo "Code-signing identity '$IDENTITY' is already installed."
  exit 0
fi

if security find-certificate -c "$IDENTITY" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "error: certificate '$IDENTITY' exists but is not a valid code-signing identity." >&2
  echo "       Open Keychain Access, find '$IDENTITY', and set Trust > Code Signing to Always Trust." >&2
  exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/taskbarra-codesign.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
chmod 700 "$TEMP_DIR"

CERT_CONFIG="$TEMP_DIR/codesign.conf"
PRIVATE_KEY="$TEMP_DIR/codesign.key"
CERTIFICATE="$TEMP_DIR/codesign.crt"
PKCS12="$TEMP_DIR/codesign.p12"
CERTIFICATE_PASSWORD="$(openssl rand -base64 24)"

cat >"$CERT_CONFIG" <<EOF
[ req ]
distinguished_name = req_name
prompt = no

[ req_name ]
CN = $IDENTITY

[ extensions ]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,1.3.6.1.5.5.7.3.3
1.2.840.113635.100.6.1.14 = critical,DER:0500
EOF

openssl genrsa -out "$PRIVATE_KEY" 2048
openssl req -x509 -new -config "$CERT_CONFIG" -nodes \
  -key "$PRIVATE_KEY" -extensions extensions -sha256 -days 3650 \
  -out "$CERTIFICATE"

if [[ "$(openssl version)" == OpenSSL\ 3* ]]; then
  openssl pkcs12 -legacy -export \
    -inkey "$PRIVATE_KEY" -in "$CERTIFICATE" -out "$PKCS12" \
    -passout "pass:$CERTIFICATE_PASSWORD"
else
  openssl pkcs12 -export \
    -inkey "$PRIVATE_KEY" -in "$CERTIFICATE" -out "$PKCS12" \
    -passout "pass:$CERTIFICATE_PASSWORD"
fi

security import "$PKCS12" -k "$KEYCHAIN" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$CERTIFICATE"

if ! security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -F "\"$IDENTITY\"" >/dev/null; then
  echo "error: '$IDENTITY' was imported but is not available for code signing." >&2
  echo "       Open Keychain Access, find '$IDENTITY', and set Trust > Code Signing to Always Trust." >&2
  exit 1
fi

echo "Installed stable local code-signing identity: $IDENTITY"
echo "Taskbarra builds will now use it automatically."
