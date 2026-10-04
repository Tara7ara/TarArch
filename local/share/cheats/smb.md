# SMB

## Enumerar recursos
smbclient -L //$T -N
netexec smb $T --shares -u '' -p ''
enum4linux -a $T

## Conectar a un recurso
smbclient //$T/recurso -N
# dentro: get fichero / put fichero / recurse ON; mget *

## Con credenciales (netexec)
netexec smb $T -u usuario -p 'Password123'
netexec smb $T -u usuario -p 'Password123' --shares
netexec smb $T -u usuario -H <hash_ntlm>          # pass-the-hash
netexec smb $T -u users.txt -p pass.txt --continue-on-success

## Vulnerabilidades
nmap --script smb-vuln* -p 445 $T
