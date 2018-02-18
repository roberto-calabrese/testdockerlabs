#!/bin/bash


source "$(pwd)/utils/spinner.sh"


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
        start_spinner "attendo ${ATTESA_GALERA_SEED} secondi per riprovare"
        sleep ${ATTESA_GALERA_SEED}
        stop_spinner $?
        checkDbSeed
    fi
}

next1() {
    ## PORTAINER
    echo -e "### INSTALL PORTAINER"


     docker service create \
    --name portainer \
    -p 9000:9000 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
    portainer/portainer \
    -H unix:///var/run/docker.sock
    echo -e "### INSTALL PORTAINER OK"


    echo -e "### INSTALL GALERA"
    cd ./galera_cluster/
    docker stack deploy -c docker-compose.yml db
    echo -e "### INSTALL GALERA OK"

    checkDbSeed

}


next2() {
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






