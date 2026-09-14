#!/usr/bin/env python3
# Escucha el socket de eventos de Hyprland y activa/desactiva el modo RDP
# automaticamente segun si la ventana con foco es xfreerdp o no.
import os
import socket
import subprocess

RDP_CLASS = "xfreerdp"
RDP_MODE_SCRIPT = os.path.expanduser("~/.local/bin/rdp-mode.sh")

sock_path = os.path.join(
    os.environ["XDG_RUNTIME_DIR"],
    "hypr",
    os.environ["HYPRLAND_INSTANCE_SIGNATURE"],
    ".socket2.sock",
)


def set_mode(is_rdp: bool) -> None:
    subprocess.run([RDP_MODE_SCRIPT, "on" if is_rdp else "off"], check=False)


def main() -> None:
    current = False
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(sock_path)
        buf = ""
        while True:
            data = s.recv(4096).decode(errors="ignore")
            if not data:
                break
            buf += data
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                if line.startswith("activewindow>>"):
                    payload = line[len("activewindow>>"):]
                    cls = payload.split(",", 1)[0]
                    is_rdp = cls == RDP_CLASS
                    if is_rdp != current:
                        current = is_rdp
                        set_mode(is_rdp)


if __name__ == "__main__":
    main()
