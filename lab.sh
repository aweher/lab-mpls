#!/bin/bash

# Lab management script

# Developed by Ariel S. Weher
# ariel[at]weher[dot]net

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

    if ! command -v containerlab &> /dev/null; then
        echo "containerlab is not installed."
        read -p "Do you want to install it now? (y/n): " choice
        case "$choice" in 
            y|Y ) curl -ksL https://containerlab.dev/setup | sudo -E bash -s "all";;
            n|N ) echo "Please install containerlab to use this script.";;
            * ) echo "Invalid choice. Please install containerlab to use this script.";;
        esac
    fi
}

check_if_docker_images_exists(){
    DIMAGES=$(grep -E "image: " "${LABFILE}" | awk '{print $2}' | sort | uniq)
    for DIMAGE in $DIMAGES; do
        if ! docker image inspect $DIMAGE &> /dev/null; then
            echo "Image $DIMAGE not found. Building it.."
            echo "Please wait..."
            # Build the images from local Dockerfiles
            #make
        fi
    done
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
    for CONTAINER in $(docker ps --format '{{.Names}}' | grep ${LABPFX} | sort | xargs); 
        do
        echo "Post-configuring ${CONTAINER}"
        # No remover estas lineas, son necesarias para que el lab funcione
        docker exec -ti $CONTAINER ip link add dev Loopback0 type dummy
        docker exec -ti $CONTAINER ip link set dev Loopback0 up
        docker exec -ti $CONTAINER ip route del default;
        docker exec -ti $CONTAINER ip -6 route del default;
        docker exec -ti $CONTAINER ip addr flush dev eth0
        docker exec -ti $CONTAINER ip -6 addr flush dev eth0
        docker exec -ti $CONTAINER ip link set eth0 down
        docker exec -ti $CONTAINER sysctl -w net.ipv4.fib_multipath_hash_policy=2
        docker exec -ti $CONTAINER sysctl -w net.ipv6.fib_multipath_hash_policy=2
        docker exec -ti $CONTAINER /etc/frr/enable-mpls.sh
        # Proceso las configuraciones especiales de cada nodo
        NODENAME=$(echo $CONTAINER | cut -d '-' -f3-)
        if [ -f .working-configs/${NODENAME}/runme.sh ]; then
            echo "Running post configuration script for ${NODENAME}"
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
    echo
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
    if command -v xdg-open &> /dev/null; then
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
    fi
}

lab_backupworking(){
    echo "Creating backup of working configs..."
    echo
    NOW=$(date +%Y%m%d%H%M%S)
    sudo mkdir -p backup/
    sudo tar cvfz backup/working-configs-${NOW}.tar.gz .working-configs
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

if ! command -v wireshark &> /dev/null; then
    echo "Wireshark is not installed."
    read -p "Do you want to install it now? (y/n): " choice
    case "$choice" in 
        y|Y ) sudo apt-get update && sudo apt-get install -y wireshark;;
        n|N ) echo "Please install Wireshark to use this feature.";;
        * ) echo "Invalid choice. Please install Wireshark to use this feature.";;
    esac
fi

lab_wireshark_capture(){
    echo "Capturing traffic on ANY interface..."
    echo

    if ! command -v dialog &> /dev/null; then
        echo "dialog is not installed."
        read -p "Do you want to install it now? (y/n): " choice
        case "$choice" in 
            y|Y ) sudo apt-get update && sudo apt-get install -y dialog;;
            n|N ) echo "Please install dialog to use this feature.";;
            * ) echo "Invalid choice. Please install dialog to use this feature.";;
        esac
    fi

    # Get the list of nodes
    NODES=$(cat ${LABFILE} | yq '.topology.nodes | to_entries | .[] | .key ' | sort | xargs)

    # Create a temporary file to store the dialog output
    TMPFILE=$(mktemp)

    # Create the dialog menu for node selection
    dialog --clear --title "Select Device" --menu "Choose a device to capture traffic from:" 15 50 8 $(for NODE in $NODES; do echo $NODE $NODE; done) 2> $TMPFILE

    # Get the selected node
    NODE=$(cat $TMPFILE)

    # Clean up the temporary file
    rm -f $TMPFILE

    if [ -z "$NODE" ]; then
        echo "No device selected. Exiting..."
        exit 1
    fi

    # Get the list of interfaces for the selected node
    INTERFACES=$(sudo -E ip netns exec ${LABPFX}-${NODE} ip link show | awk -F: '$0 !~ "vir|wl|^[^0-9]"{print $2}' | tr -d ' ' | xargs)

    # Create the dialog menu for interface selection
    TMPFILE=$(mktemp)
    dialog --clear --title "Select Interface" --menu "Choose an interface to capture traffic from:" 15 50 8 any any $(for INTERFACE in $INTERFACES; do echo $INTERFACE $INTERFACE; done) 2> $TMPFILE

    # Get the selected interface
    INTERFACE=$(cat $TMPFILE | cut -d "@" -f1)

    # Clean up the temporary file
    rm -f $TMPFILE

    if [ -z "$INTERFACE" ]; then
        echo "No interface selected. Exiting..."
        exit 1
    fi

    sudo -E ip netns exec ${LABPFX}-${NODE} tcpdump -nni "${INTERFACE}" -w - | wireshark -k -i -
}

lab_collect_running_config(){
    NODE=$2
    if [ -z "$NODE" ]; then
        echo "Usage: $0 collect <node>"
        exit 1
    fi
    echo "Collecting running config from ${NODE}..."
    NOW=$(date +%Y%m%d%H%M%S)
    mkdir -p backup/configs/${NODE}/${NOW}
    if [ -d configs/${NODE} ]; then
        docker cp ${LABPFX}-${NODE}:/etc/frr/frr.conf backup/configs/${NODE}/${NOW}/frr.conf
        echo "Running config collected: Check configs/${NODE}/frr.conf"
    else
        echo "Error collecting running config. Directory configs/${NODE} does not exist"
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

lab_status(){
    if [ -d .working-configs ]; then
        echo "Lab is configured"
        if $CLABCMD inspect -t ${LABFILE} &> /dev/null; then
            $CLABCMD inspect -t ${LABFILE}
        else
            echo "Lab is not running"
        fi
    else
        echo "Lab is not configured yet"
    fi
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
check_if_docker_images_exists

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
        lab_wireshark_capture
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
    status)
        lab_status
        ;;
esac

# EOF