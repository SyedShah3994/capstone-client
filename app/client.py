import hashlib
import json
import os
import socket
import sys
import time

SERVER_HOST = os.environ.get("SERVER_HOST", "localhost")
SERVER_PORT = int(os.environ.get("SERVER_PORT", "5000"))
SAVE_DIR = "/clientdata"


def connect_with_retry(retries=30, delay=5):
    for attempt in range(1, retries + 1):
        try:
            return socket.create_connection((SERVER_HOST, SERVER_PORT), timeout=10)
        except OSError as e:
            print(f"[client] attempt {attempt}/{retries}: cannot connect ({e}), retry in {delay}s", flush=True)
            time.sleep(delay)
    print("[client] could not reach the server, giving up", flush=True)
    sys.exit(1)


def read_header(sock):
    buf = b""
    while not buf.endswith(b"\n"):
        chunk = sock.recv(1)
        if not chunk:
            raise ConnectionError("connection closed before the header ended")
        buf += chunk
    return json.loads(buf.decode())


def read_exact(sock, n):
    data = b""
    while len(data) < n:
        chunk = sock.recv(n - len(data))
        if not chunk:
            raise ConnectionError("connection closed before the whole file arrived")
        data += chunk
    return data


def main():
    os.makedirs(SAVE_DIR, exist_ok=True)
    print(f"[client] connecting to {SERVER_HOST}:{SERVER_PORT}", flush=True)

    with connect_with_retry() as sock:
        meta = read_header(sock)
        content = read_exact(sock, meta["size"])

    path = os.path.join(SAVE_DIR, meta["filename"])
    with open(path, "wb") as f:
        f.write(content)
    print(f"[client] saved {path} ({len(content)} bytes)", flush=True)

    calculated = hashlib.sha256(content).hexdigest()
    print(f"[client] received checksum : {meta['sha256']}", flush=True)
    print(f"[client] calculated checksum: {calculated}", flush=True)

    if calculated == meta["sha256"]:
        print("[client] CHECKSUM OK - file is intact", flush=True)
        sys.exit(0)
    print("[client] CHECKSUM MISMATCH - file is corrupted", flush=True)
    sys.exit(2)


if __name__ == "__main__":
    main()
