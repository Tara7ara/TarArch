#!/usr/bin/env python3
"""
Autoriza una vez el acceso de solo lectura a Google Calendar para el Centro de
Control. Abre el navegador, recoge el código en un servidor local de un solo uso
y guarda el refresh token en ~/.config/tararch/google/token.json.
"""
import base64
import hashlib
import http.server
import json
import os
import secrets
import subprocess
import sys
import urllib.parse
import urllib.request

GOOGLE_DIR = os.path.expanduser("~/.config/tararch/google")
CLIENT_FILE = os.path.join(GOOGLE_DIR, "client_secret.json")
TOKEN_FILE = os.path.join(GOOGLE_DIR, "token.json")
SCOPE = "https://www.googleapis.com/auth/calendar.readonly"

if not os.path.exists(CLIENT_FILE):
    sys.exit(f"Falta {CLIENT_FILE} (credencial OAuth de tipo 'App de escritorio').")

with open(CLIENT_FILE, "r", encoding="utf-8") as f:
    client = json.load(f)["installed"]

verifier = secrets.token_urlsafe(64)
challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
state = secrets.token_urlsafe(16)
result = {}


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        if query.get("state", [""])[0] == state:
            result["code"] = query.get("code", [""])[0]
            result["error"] = query.get("error", [""])[0]
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write("Listo, ya puedes cerrar esta pestaña.".encode())

    def log_message(self, *args):
        pass


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
redirect_uri = f"http://127.0.0.1:{server.server_port}"

auth_url = client["auth_uri"] + "?" + urllib.parse.urlencode({
    "client_id": client["client_id"],
    "redirect_uri": redirect_uri,
    "response_type": "code",
    "scope": SCOPE,
    "access_type": "offline",
    "prompt": "consent",
    "code_challenge": challenge,
    "code_challenge_method": "S256",
    "state": state,
})

print("Abriendo el navegador. Si no se abre, entra aquí:\n" + auth_url)
subprocess.Popen(["xdg-open", auth_url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

while "code" not in result:
    server.handle_request()

if not result["code"]:
    sys.exit(f"Autorización cancelada: {result['error']}")

body = urllib.parse.urlencode({
    "code": result["code"],
    "client_id": client["client_id"],
    "client_secret": client["client_secret"],
    "redirect_uri": redirect_uri,
    "grant_type": "authorization_code",
    "code_verifier": verifier,
}).encode()
with urllib.request.urlopen(client["token_uri"], data=body, timeout=15) as resp:
    token = json.load(resp)

if "refresh_token" not in token:
    sys.exit("Google no ha devuelto refresh token; quita el acceso en myaccount.google.com/permissions y repite.")

fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump({"refresh_token": token["refresh_token"]}, f)

print(f"Token guardado en {TOKEN_FILE}. El Centro de Control ya lee Google Calendar.")
