# Enumeración web (gobuster / ffuf)

## Directorios (lista con Super+L = seclists)
gobuster dir -u http://$T -w $(seclists -p) -t 50 -o gobuster.txt
ffuf -u http://$T/FUZZ -w $(seclists -p) -mc 200,204,301,302,307,401,403

## Extensiones
gobuster dir -u http://$T -w $(seclists -p) -x php,txt,html,bak

## Subdominios / vhosts (cambia la cabecera Host)
ffuf -u http://$T -H "Host: FUZZ.$T" -w $(seclists -p) -fs <tam_respuesta_base>

## Fuerza bruta de parámetros
ffuf -u "http://$T/page.php?FUZZ=1" -w $(seclists -p) -fs <tam>
