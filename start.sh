#!/bin/bash


source "$(pwd)/utils/spinner.sh"
source "$(pwd)/utils/progress_bar.sh"


ATTESA_GALERA_SEED=30


## FUNZIONI


attesa(){
    for i in `seq 1 $1`;
    do
        echo "attendo $(echo $(( ${1} - i ))) secondi"
        sleep 1
    done
}


checkDbSeed () {

    echo -e "### CONTROLLO GALERA SEED "

    if [ $(docker service ls | grep db_db-seed  | awk '{print $4}') == 1/1 ]
    then
        echo "OK"
        next2
    else
        echo "GALERA SEED -> KO -> attendo ${ATTESA_GALERA_SEED} secondi."
        #attesa ${ATTESA_GALERA_SEED}
        #start_spinner "attendo ${ATTESA_GALERA_SEED} secondi per riprovare"
        #sleep ${ATTESA_GALERA_SEED}
        #stop_spinner $?
        progress-bar ${ATTESA_GALERA_SEED}
        checkDbSeed
    fi
}

next1() {

    echo -e "### INSTALLO PORTAINER"
     docker service create \
    --name portainer \
    -p 9000:9000 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
    portainer/portainer \
    -H unix:///var/run/docker.sock
    echo -e "### PORTAINER OK"


    echo -e "### INSTALLO GALERA"
    cd ./galera_cluster/
    docker stack deploy -c docker-compose.yml db
    echo -e "### CLUSTER GALERA OK"

    checkDbSeed

}


next2() {


echo "### CONTROLLO CHE I NODI CLUSTER NON SIANO GIA' ATTIVI"

if [ $(docker service ls | grep db_db  | awk '{print $4}') == 2/2 ]
    then
        echo "### NODI GIA' ATTIVI"
        next3
    else
        echo -e "### AZIONO I NODI CLUSTER GALERA"
        docker service scale db_db=2
        echo -e "### DISATTIVO IL DB SEED GALERA"
        docker service scale db_db-seed=0
        next3
    fi
}


next3(){
    echo -e "### INSTALLO SWARM PROM"
    cd ../
    git clone https://github.com/stefanprodan/swarmprom.git
    cd swarmprom
    ADMIN_USER=admin \
    ADMIN_PASSWORD=admin \
    SLACK_URL=https://hooks.slack.com/services/TOKEN \
    SLACK_CHANNEL=devops-alerts \
    SLACK_USER=alertmanager \
    docker stack deploy -c docker-compose.yml mon
    next4
}

next4(){
    cd ~/testdockerlabs/zabbix

#    docker run -d -v /var/lib/mysql --name zabbix-db-storage busybox:latest
#
#    docker run \
#    -d \
#    --name zabbix-db \
#    -v /backups:/backups \
#    -v /etc/localtime:/etc/localtime:ro \
#    --volumes-from zabbix-db-storage \
#    --env="MARIADB_USER=zabbix" \
#    --env="MARIADB_PASS=my_password" \
#    monitoringartist/zabbix-db-mariadb
#
#
#   docker run \
#    -d \
#    --name zabbix \
#    -p 8888:80 \
#    -p 10051:10051 \
#    -v /etc/localtime:/etc/localtime:ro \
#    --link zabbix-db:zabbix.db \
#    --env="ZS_DBHost=zabbix.db" \
#    --env="ZS_DBUser=zabbix" \
#    --env="ZS_DBPassword=my_password" \
#    monitoringartist/zabbix-xxl:latest
# Wait ~30 seconds for Zabbix initialization
# Zabbix web will be available on the port 80, Zabbix server on the port 10051
# Default credentials: Admin/zabbix

    docker stack deploy -c docker-compose.yml zab

}


next1






