"""Datagram receiver for scripts/bench.sh: binds argv[1], drains until killed."""
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM); s.bind(sys.argv[1]); s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 8 << 20)
print("READY", flush=True)
while True: s.recv(4096)
