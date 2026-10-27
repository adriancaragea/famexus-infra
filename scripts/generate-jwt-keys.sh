#!/usr/bin/env bash
# Creates the RSA key pair the gateway uses to sign JWTs for the services,
# and copies the public key into each service. Skips if a key already exists.
set -euo pipefail

cd "$(dirname "$0")/../.."
keys=famexus-gateway/storage/keys
mkdir -p "$keys"

if [ ! -f "$keys/jwt-private.pem" ]; then
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$keys/jwt-private.pem"
  openssl rsa -in "$keys/jwt-private.pem" -pubout -out "$keys/jwt-public.pem"
  echo "✓ generated gateway key pair"
fi

for svc in famexus-todo famexus-calendar wallit; do
  mkdir -p "$svc/storage/keys"
  cp "$keys/jwt-public.pem" "$svc/storage/keys/jwt-public.pem"
  echo "✓ public key copied to $svc"
done
