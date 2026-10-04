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

## Guardar el informe
tarascan $T -o                    # Markdown en el directorio actual
tarascan $T -o informe.md         # con nombre
