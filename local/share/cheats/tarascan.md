# TaraScan (tu wrapper de recon)

## Recon de un objetivo
tarascan $T                       # usa $T / set-target si no pasas nada
tarascan 10.10.10.5
tarascan ejemplo.com -o           # guarda el informe en Markdown

## Más a fondo
tarascan $T --full                # nmap a los 65535 puertos (lento)
tarascan $T --deep                # descubrimiento recursivo con feroxbuster

## Elegir / omitir herramientas
tarascan $T --only nmap,whatweb,nuclei
tarascan $T --skip nikto,nuclei

## Intrusivo (solo objetivos autorizados)
tarascan $T --sqli                # sqlmap contra la web detectada
tarascan $T --brute ssh           # hydra contra el servicio (ssh, ftp, http-get...)

## Mapa de la red local
tarascan --net                    # tu subred actual
tarascan --net 172.30.0.0/24      # una subred concreta (= tarascan-lab)
tarascan-lab                      # alias del laboratorio Docker

## IA
tarascan $T --ai                  # resumen + vectores + comandos (necesita TARASCAN_AI_KEY)
tarascan $T --guided              # copiloto iterativo: propone, ejecutas, reanaliza
tarascan $T --auto                # copiloto manos libres: ejecuta la mejor sugerencia solo

## OSINT / web / auditoría
tarascan osint ejemplo.com        # crt.sh, SPF/DMARC/DKIM, cabeceras (pasivo)
tarascan web http://10.10.10.5    # swagger/openapi/graphql + CORS
tarascan audit ssh 10.10.10.5     # config débil: ssh | tls | smb
tarascan cve vsftpd 2.3.4         # exploits conocidos (searchsploit)

## Utilidades
tarascan hash 5f4dcc3b...         # tipo de hash + modo Hashcat/John
tarascan decode SGVsbG8=          # decodifica en cascada (base64, hex, rot13...)
tarascan jwt eyJhbGc...           # desglosa el JWT y avisa de alg=none / exp
tarascan shell -p 4444            # reverse shells con tu IP ya puesta (--b64 / --url)
tarascan serve 8000               # servidor HTTP + comandos de descarga en la víctima
tarascan pivot                    # chuleta de túneles (Chisel, SSH, Ligolo-ng)
tarascan gtfobins find            # privesc offline: sudo/SUID/capabilities (GTFOBins)

## Sesión (workspaces, notas, informe)
tarascan ws init lab-htb          # crea ~/audit/lab-htb/ y lo activa
tarascan note "SMB sesion nula"   # apunta con timestamp en el workspace activo
tarascan report 10.10.10.5        # informe consolidado (--html para HTML)
tarascan diff 10.10.10.5          # compara los dos últimos escaneos

## Guardar el informe
tarascan $T -o                    # Markdown en el directorio actual
tarascan $T -o informe.md         # con nombre

## Autocompletado
tarascan completion zsh > ~/.local/share/zsh/site-functions/_tarascan
