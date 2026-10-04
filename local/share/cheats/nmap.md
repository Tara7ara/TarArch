# nmap

## Descubrir hosts (sin escanear puertos)
nmap -sn 192.168.1.0/24

## Escaneo rápido completo + versiones + scripts por defecto
nmap -sC -sV -oN nmap/$T.txt $T

## Todos los puertos TCP (primero) y luego versiones solo en los abiertos
nmap -p- --min-rate 2000 -oN nmap/allports.txt $T
nmap -p 22,80,443 -sC -sV -oN nmap/detalle.txt $T

## UDP (lento, los típicos)
sudo nmap -sU --top-ports 20 $T

## Saltar ping (host que no responde a ICMP)
nmap -Pn -sC -sV $T
