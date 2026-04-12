#!/usr/bin/env python3
"""
Simple SPA static file server:
- Serves real files when they exist (assets, js, css, images).
- Falls back to index.html for client-side routes (e.g. /migrate, /billing).
"""

from __future__ import annotations

import argparse
import os
import posixpath
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler


class SpaHandler(SimpleHTTPRequestHandler):
    # Set per-server via constructor.
    def __init__(self, *args, directory: str, index_file: str, **kwargs):
        self._spa_root = os.path.abspath(directory)
        self._index_file = index_file
        super().__init__(*args, directory=directory, **kwargs)

    def translate_path(self, path: str) -> str:
        # Use SimpleHTTPRequestHandler translation logic with our directory.
        # This ensures existing files are served normally.
        # For our fallback decisions, we still check existence ourselves below.
        return super().translate_path(path)

    def do_GET(self):  # noqa: N802
        # Normalize the URL path.
        # SimpleHTTPRequestHandler may already handle '?' query; do_GET sees the raw path.
        url_path = self.path.split("?", 1)[0].split("#", 1)[0]
        if not url_path.startswith("/"):
            url_path = "/" + url_path

        # Map URL path -> filesystem path (relative to server directory).
        rel = posixpath.normpath(url_path).lstrip("/")
        fs_path = os.path.join(self._spa_root, rel)

        # If it looks like a request for a real file, serve it (404 if missing).
        # If not a real file, fall back to index.html.
        # Also treat directory requests as index.html.
        if os.path.isdir(fs_path):
            # e.g. / -> /index.html
            return self.serve_index()

        if os.path.exists(fs_path) and not os.path.isdir(fs_path):
            return super().do_GET()

        # SPA route fallback
        return self.serve_index()

    def serve_index(self):
        # Ensure the index file is returned with correct content-type.
        # We'll serve it by calling super().do_GET against index_file path.
        self.path = "/" + posixpath.normpath(self._index_file)
        return super().do_GET()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--dir", type=str, required=True)
    parser.add_argument("--index", type=str, default="index.html")
    parser.add_argument("--bind", type=str, default="127.0.0.1")
    args = parser.parse_args()

    directory = os.path.abspath(args.dir)
    index_file = args.index
    index_path = os.path.join(directory, index_file)
    if not os.path.exists(index_path):
        raise SystemExit(f"index file not found: {index_path}")

    handler_factory = lambda *h_args, **h_kwargs: SpaHandler(  # noqa: E731
        *h_args,
        directory=directory,
        index_file=index_file,
        **h_kwargs,
    )

    httpd = ThreadingHTTPServer((args.bind, args.port), handler_factory)
    print(f"SPA server running on http://{args.bind}:{args.port} serving {directory}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()

