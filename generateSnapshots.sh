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
