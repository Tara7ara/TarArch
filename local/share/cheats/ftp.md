# FTP

## Acceso anónimo
ftp $T            # usuario: anonymous  ·  contraseña: (vacía)
# dentro: ls -la / get fichero / put fichero / binary / mget *

## Rápido con netexec
netexec ftp $T -u usuario -p 'Password123'
netexec ftp $T -u anonymous -p ''

## Enumerar y fuerza bruta
nmap --script ftp-anon,ftp-syst -p 21 $T
hydra -L $(seclists -p) -P $(seclists -p) ftp://$T
