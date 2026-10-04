# John the Ripper

## Crackear con diccionario (rockyou vía Super+L)
john --wordlist=$(seclists -p) hashes.txt
john --wordlist=$(seclists -p) --format=raw-md5 hashes.txt

## Ver crackeadas / estado
john --show hashes.txt
john --status

## Preparar hashes de ficheros (los *2john)
ssh2john id_rsa > hash.txt
zip2john fichero.zip > hash.txt
# luego: john --wordlist=$(seclists -p) hash.txt

## Reglas (muta el diccionario)
john --wordlist=$(seclists -p) --rules hashes.txt
