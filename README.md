# wb40-backups

> Pregunta 9 : Crea un script que haga snapshots de todas las maquinas virtuales en tu proyecto de hetzner cloud, y mira como configurar un cron que lo ejecute por las noches.

Instalamos jq para gestionar los json resultantes:
```	
  apt install -y jq
```
He generado el API token: 
API_TOKEN=***********

Para generar un snapshot:
```
curl \
	-X POST \
	-H "Authorization: Bearer $API_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"description":"my image","labels":{"labelkey":"value"},"type":"snapshot"}' \
	'https://api.hetzner.cloud/v1/servers/{id}/actions/create_image'
```
Para listar los servers:
```
curl \
	-H "Authorization: Bearer $API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers'
```

Este es el script que se ha desarrollado:
```
#!/bin/bash

API_TOKEN=
RESPFILE=allservers.resp

function getAllServers(){
    curl \
	-H "Authorization: Bearer $API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers' 2> /dev/null | \
        jq '.servers[] | {id,name}' | \
        tee $RESPFILE
}

function countServers(){
    [ -f $RESPFILE ] || getAllServers > /dev/null
    cat $RESPFILE | jq -s '. | length'
}

function getServerId(){
    INDEX=$1
    EXP=".[$INDEX].id"
    cat $RESPFILE | jq -s $EXP
}

function getAllServersId(){
    getServerId
}

function getServerName(){
    INDEX=$1
    EXP=".[$INDEX].name"
    cat $RESPFILE | jq -s $EXP
}

function getAllServersNames(){
    getServerName
}

function printHumanServerList(){
# Muestra de manera entendible la información obtenida
    [ -z $SRVNUM ] && SRVNUM=`countServers`
    for I in `seq 0 $(expr $SRVNUM - 1)`; do
        echo "$I: Servidor $(getServerName $I) con id $(getServerId $I)"
    done
}

function createServerSnapshot(){
    SRVID=$1
    LABEL=`echo $2  | tr -d '"'`
    TS=`date +%s`
    SNAPNAME="$LABEL-$TS"
    echo "Creando el snapshot $SNAPNAME"
    curl \
        -X POST \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"description":"'$SNAPNAME'","labels":{"creationtime":"'$TS'"},"type":"snapshot"}' \
        'https://api.hetzner.cloud/v1/servers/'${SRVID}'/actions/create_image'
}

getAllServers > /dev/null
SRVNUM=`countServers`
echo "He encontrado $SRVNUM servidores"
printHumanServerList
for I in `seq 0 $(expr $SRVNUM - 1)`; do
    createServerSnapshot $(getServerId $I) $(getServerName $I)
done
```
Para automatizar en un cron vamos a crear un fichero ***/etc/cron.d/heztnerbackups*** que lanzará el script cada noche a las 5:10 de la mañana. Este es el contenido:
`10 5 * * * root bash /root/generateSnapshot.sh` 

> Pregunta 10

> A la hora de realizar dumps de bases de datos, por ejemplo mysql, segun vayamos teniendo más datos, cada vez tardará más. Es probable que haya entornos que tengamos que optar por otras estrategias de backup, tipo lvmbackup.
> Cuando un dump de sql tarde mucho, cambiaremos el storage donde se encuentra la partición a lvm y realizaremos backups usando lvmsnapshot, que será mucho más rápido tanto en dump como en restore.
> Conecta un nuevo disco al wordpress y particiona el mismo usando LVM. Crearemos una partición ext4 que sea la mitad del volumen. Cuando lo tengas para el servicio de mysql, mueve los datos al LVM y montalo en el path correspondiente para que funcione el servicio. Enciente y comprueba que todo funciona.
> Invesiga como hacer un backup y restaurar usando LVM snapshot.
