#!/bin/bash


source "$(pwd)/utils/spinner.sh"
source "$(pwd)/utils/progress_bar.sh"


ATTESA_GALERA_SEED=20


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
        progress_bar ${ATTESA_GALERA_SEED}
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
    echo -e "### AZIONO I NODI CLUSTER GALERA"
    docker service scale db_db=2
    next3
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

}


next1






