#!/usr/bin/env python3
"""Servidor local pra testar o export Web do Godot no celular (mesma WiFi).

Godot 4 Web usa threads (SharedArrayBuffer) → exige os headers
Cross-Origin-Opener-Policy / Cross-Origin-Embedder-Policy. O http.server
padrão não os envia; este envia.

Uso:  python3 serve_web.py
Depois abra no celular:  http://<IP-DO-MAC>:8000
"""
import http.server
import socketserver

PORT = 8000
DIRECTORY = "build/web"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Servindo {DIRECTORY} em http://0.0.0.0:{PORT}")
    print("No celular (mesma WiFi): http://192.168.7.98:%d" % PORT)
    httpd.serve_forever()
