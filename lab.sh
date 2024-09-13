#!/bin/bash
# Lab management script

if [ -z "$1" ]; then
    echo "Usage: $0 {run|start|stop|restart|configure|destroy|cleanup|connect|backup|uninstall}"
    echo
    exit 1
fi

lab_check_requirements(){
    if [[ "$(lsb_release -is)" == "Ubuntu" && "$(lsb_release -rs | cut -d. -f1)" -ge 18 ]]; then
        echo "Checking requirements..."
    else
        echo "This script requires Ubuntu version 18 or greater."
        exit 1
    fi
    if ! lsmod | grep -q mpls_router; then
        echo "Kernel module mpls_router is not available. Loading it..."
        sudo modprobe mpls_router
        sudo modprobe mpls_gso
        sudo modprobe mpls_iptunnel
        sudo sysctl -w net.mpls.platform_labels=1048575
    fi
    if ! command -v yq &> /dev/null; then
        echo "yq is not installed."
        read -p "Do you want to install it now? (y/n): " choice
        case "$choice" in 
            y|Y ) sudo apt-get update && sudo apt-get install -y yq;;
            n|N ) echo "Please install yq to use this script.";;
            * ) echo "Invalid choice. Please install yq to use this script.";;
        esac
    fi
}

lab_destroy(){
    echo "Destroying lab..."
    echo
    if [ -d .working-configs ]; then
        $CLABCMD destroy -t ${LABFILE}
        sudo killall $CLABCMD
        sudo rm -rf .working-configs
    else
        echo "No working configs found. You need to run \"$0 configure\" for the first time"
        exit 1
    fi
}

lab_start(){
    echo "Starting lab..."
    echo
    if [ -d .working-configs ]; then
        $CLABCMD deploy -t ${LABFILE}
        lab_post_start
    else
        echo "No working configs found. You need to run \"$0 configure\" for the first time"
        exit 1
    fi
}

lab_post_start(){
    echo "Running post configuration scripts..."
    echo
    for CONTAINER in $(docker ps --format '{{.Names}}' | grep ${LABPFX} | sort |xargs); 
        do
        echo "Post-configuring ${CONTAINER}"
        # No remover estas lineas, son necesarias para que el lab funcione
        docker exec -ti $CONTAINER ip link add dev Loopback0 type dummy
        docker exec -ti $CONTAINER ip link set dev Loopback0 up
        docker exec -ti $CONTAINER ip route del default;
        docker exec -ti $CONTAINER ip -6 route del default;
        # Proceso las configuraciones especiales de cada nodo
        NODENAME=$(echo $CONTAINER | cut -d '-' -f3-)
        if [ -f .working-configs/${NODENAME}/runme.sh ]; then
            docker exec -ti $CONTAINER bash /etc/frr/runme.sh
        fi
    done  
}

lab_stop(){
    echo "Stopping lab..."
    echo
    if [ -d .working-configs ]; then
        $CLABCMD destroy -t ${LABFILE}
        sudo killall $CLABCMD
    fi
}

lab_restart(){
    echo "Restarting lab..."
    echo
    lab_stop
    lab_start
}

lab_configure(){
    echo "Configuring lab..."
    echo
    
    if [ -d .working-configs ]; then
        echo ".working-configs directory already exists. Stopping"
        exit 1
    fi

    for NODE in $(cat ${LABFILE} | yq '.topology.nodes | to_entries | .[] | .key ' | sort | xargs); do
        echo "Configuring ${NODE}"
        mkdir -p ./.working-configs/$NODE
        cp ./configs/default/* ./.working-configs/$NODE/
        if [ -d configs/${NODE} ] && [ "$(ls -A configs/${NODE})" ]; then
            mkdir -p ./.working-configs/${NODE}
            cp ./configs/${NODE}/* ./.working-configs/$NODE/
        fi
    done
}

lab_cleanup(){
    echo "Cleaning lab..."
    echo
    lab_stop > /dev/null 2>&1
    
    sudo rm -rf .*.yml.bak

    if [ -d clab-${LABPFX} ]; then
        sudo rm -rf clab-${LABPFX}
    fi

    if [ -d .working-configs ]; then
        sudo rm -rf ./.working-configs
    fi
}

lab_have_fun(){
    if ! command -v konsole &> /dev/null; then
        echo "Konsole is not installed."
        read -p "Do you want to install it now? (y/n): " choice
        case "$choice" in 
            y|Y ) sudo apt-get install -y konsole;;
            n|N ) echo "Please install konsole to use this feature.";;
            * ) echo "Invalid choice. Please install konsole to use this feature.";;
        esac
    fi
    echo "Connecting to console..."
    echo
    TMPFILE=$(mktemp)
    for NODE in $(cat ${LABFILE} | yq '.topology.nodes | to_entries | .[] | .key ' | sort | xargs); do
        echo "title: ${NODE};; command: docker exec -ti ${LABPFX}-${NODE} bash">> ${TMPFILE}
    done
    konsole --tabs-from-file ${TMPFILE} &
}

lab_backupworking(){
    echo "Creating backup of working configs..."
    echo
    NOW=$(date +%Y%m%d%H%M%S)
    sudo mkdir -p backups/
    sudo tar cvfz backups/working-configs-${NOW}.tar.gz .working-configs
}

lab_uninstall(){
    lab_stop
    lab_cleanup
    clear
    echo "MPLS LAB"
    echo
    echo "You are about to destroy all instances and remove all unused container images"
    echo 
    echo "Press enter to continue, Ctrl+C to cancel..."

    read key

    docker container prune
    docker network prune
    docker image prune
}

lab_open_graph(){
    echo "Creating graph..."
    echo
    $CLABCMD graph -t ${LABFILE} &
    xdg-open http://0.0.0.0:50080 &
}

lab_wireshark_any(){
    echo "Capturing traffic from $2 on ANY interface..."
    echo
    sudo -E ip netns exec ${LABPFX}-$2 tcpdump -nni any -w - | wireshark -k -i -
}

lab_collect_running_config(){
    echo "Collecting running config from $2..."
    if [ -f .working-configs/$2/frr.conf ]; then
        if [ -d configs/$2 ]; then
            cp .working-configs/$2/frr.conf configs/$2/frr.conf
            echo "Running config collected: Check configs/$2/frr.conf"
        else
            echo "Error collecting running config. Directory configs/$2 does not exist"
        fi
    else
        echo "Error collecting running config. File .working-configs/$2/frr.conf does not exist"
    fi
}

lab_boooooooom(){
    lab_stop
    lab_cleanup
}

lab_amoooooooooor(){
    # Ya se que esto esta de mas... estaba aburrido...
    lab_boooooooom
    lab_configure
    lab_start
}

lab_run(){
    clear
    echo "Just a single command to rule them all..."
    echo
    if [ ! -d .working-configs ]; then
        lab_configure
    fi
    lab_start
    lab_have_fun
    lab_open_graph
}

LABFILE=mpls.clab.yml
LABPFX=mpls
IPCMD="sudo $(which ip)"
CLABCMD="sudo $(which containerlab)"

lab_check_requirements

case "$1" in
    run)
        lab_run
        ;;
    start)
        lab_start
        ;;
    stop)
        lab_stop
        ;;
    restart)
        lab_restart
        ;;
    configure)
        lab_configure
        ;;
    destroy)
        lab_destroy
        ;;
    cleanup)
        lab_cleanup
        ;;
    connect)
        lab_have_fun
        ;;
    backup)
        lab_backupworking
        ;;
    uninstall)
        lab_uninstall
        ;;
    graph)
        lab_open_graph
        ;;
    capture)
        lab_wireshark_any $@
        ;;
    collect)
        lab_collect_running_config $@
        ;;
    boom)
        lab_boooooooom
        ;;
    amor)
        lab_amoooooooooor
        ;;
esac
