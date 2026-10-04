# Escalada de privilegios (Linux)

## Primeros vistazos
id; sudo -l
find / -perm -4000 -type f 2>/dev/null      # binarios SUID
cat /etc/crontab; ls -la /etc/cron.*
uname -a; cat /etc/os-release

## Scripts automáticos (subir y ejecutar)
./linpeas.sh
# GTFOBins para abusar de SUID/sudo: https://gtfobins.github.io

## Capabilities
getcap -r / 2>/dev/null
