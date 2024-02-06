#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'
YELLOW='\033[0;33m'

PIDs=()

system_info=$(uname -s)
if [ "$system_info" != "Linux" ]; then
    printf "${RED}%s This script bulid for Linux only! 💻 ${NC}\n"
    exit 1
fi

slashProgressBar() {
    local subject=$1
    trap 'exit' SIGTERM
    while true; do
        printf "\r%-30s\\ " "$subject"
        sleep 0.12
        printf "\r%-30s| " "$subject"
        sleep 0.12
        printf "\r%-30s/ " "$subject"
        sleep 0.12
        printf "\r%-30s- " "$subject"
        sleep 0.12
        sleep 0.12

    done
}
terminateProcesses() {
    local uPIDs=()
    
    for pid in "${PIDs[@]}"; do
        kill -15 "$pid" 2>/dev/null 
        wait "$pid" 2>/dev/null 
        if ps -p "$pid" > /dev/null; then
            uPIDs+=("$pid")
        fi
    done
    PIDs=("${uPIDs[@]}")
}


terminateScript() {
    echo -en "\033[2K\r"
    printf "\r${RED}%-10s Aborted! 🤧 ${NC}\n" "Script"
    terminateProcesses
    trap 'exit' SIGTERM
    exit 1
}


installKubectl() {
    subject="Installing Kubectl "
    slashProgressBar "$subject" &
    PIDs+=($!)
    
    if [[ -x "$(command -v kubectl)" ]]; then
        printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Kubectl"
        printf "               \n"
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null 2>&1;
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl;
        printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Kubectl"
        printf "               \n"
    fi
    terminateProcesses
}

installHelm() {
    subject="Installing Helm "
    slashProgressBar "$subject" &
    PIDs+=($!)
    
    curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > /dev/null
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Helm"
    printf "               \n"
    terminateProcesses
}

installK3D() {
    subject="Installing K3D "
    slashProgressBar "$subject" &
    PIDs+=($!)
    
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash > /dev/null
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "K3D"
    printf "\n"
}

setupClaster()
{
    # create cluster with Loadbalancer in port 8888
    subject="Creating cluster "
    slashProgressBar "$subject" &
    PIDs+=($!)
    k3d cluster create mycluster -p "8888:80@loadbalancer" > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Cluster"
    printf "               \n"
    # create namespce argocd && dev
    subject="Creating namespace argocd "
    slashProgressBar "$subject" &
    PIDs+=($!)
    kubectl create ns argocd > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Argocd,ns"
    printf "               \n"
    # kubectl create ns dev
    subject="Creating namespace Dev "
    slashProgressBar "$subject" &
    PIDs+=($!)
    kubectl create ns dev > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Dev,ns"
    printf "               \n"
    # create argocd deplement and svc
    subject="Apllay arcocd in namespace argocd "
    slashProgressBar "$subject" &
    PIDs+=($!)
    sleep 10
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null
    kubectl wait pods -n argocd --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Argocd"
    printf "               \n"
    # forward server argocd to port 8080 just for testing
    subject="Forward server argocd to port 8080 "
    slashProgressBar "$subject" &
    PIDs+=($!)
    sleep 10
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Forwarding"
    printf "               \n"
    #sewitch to argocd namespace
    kubectl config set-context --current --namespace=argocd > /dev/null
}

argocd_setAPP()
{
    # get init password in cli argo or in secret in kube
    subject="Get password of argcd "
    slashProgressBar "$subject" &
    PIDs+=($!)
    ARGOCD_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $1}')
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Password"
    printf "               \n"

    #login in argocd 
    subject="Login in to argocd "
    slashProgressBar "$subject" &
    PIDs+=($!)
    argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web > /dev/null 2>&1 && sleep 10
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Successful! 🥇 ${NC}" "Login"
    printf "                 \n"

    # Create a directory app
    subject="Create app in argocd "
    slashProgressBar "$subject" &
    PIDs+=($!)
    argocd app create app --repo https://github.com/ILKAY-BRAHIM/Inception-of-Things-IoT-.git --path 'Part_3/simple_app' --dest-namespace 'dev' --dest-server https://kubernetes.default.svc --grpc-web > /dev/null 2>&1 && sleep 10
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Create app"
    printf "                 \n"

    #View created app before sync and configuration
    printf "${YELLOW}View created app before sync and configuration ${NC}" && echo 
    argocd app get app --grpc-web && sleep 10

    #Sync the app and configure for automated synchronization
    subject="Sync app "
    slashProgressBar "$subject" &
    PIDs+=($!)
    argocd app sync app --grpc-web > /dev/null 2>&1 && sleep 10
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Sync "
    printf "                 \n"

    #??
    subject="Automated app "
    slashProgressBar "$subject" &
    PIDs+=($!)
    argocd app set app --sync-policy automated --grpc-web > /dev/null 2>&1 && sleep 10
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Automated "
    printf "                 \n"

    #if empty repo in github enabling auto prune to remove all in argocd
    subject="prune app if the repo in github removed "
    slashProgressBar "$subject" &
    PIDs+=($!)
    argocd app set app --auto-prune --allow-empty --grpc-web && sleep 10
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Prune "
    printf "                 \n"

    subject="wating all resource up of app "
    slashProgressBar "$subject" &
    PIDs+=($!)
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "APP v1"
    printf "                 \n"
    echo -n "see v1 of app in "
    URL=$(kubectl get svc -n dev | awk '{print $4 " " $5}' | sed -n "2p" | cut -d ':' -f 1 | tr " " ":" | awk '{print "http://" $1}')
    printf "${YELLOW}%s $URL ${NC} \n" | pv -qL 10
    subject="Incoming change after 1 min or more  "
    slashProgressBar "$subject" &
    PIDs+=($!)
    sleep 1
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "Timeout"
    printf "               \n"
}

docker_installation()
{
    subject="Installing DOCKER"
    slashProgressBar "$subject" &
    PIDs+=($!)
    curl -fsSL https://get.docker.com | bash > /dev/null 2>&1;
    sudo usermod -aG docker $USER;
    sudo chmod 666 /var/run/docker.sock;
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "DOCKER"
    printf "               \n"
}

argocd_installation()
{
    subject="Installing ARGOCD"
    slashProgressBar "$subject" &
    PIDs+=($!)
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "ARGOCD"
    printf "               \n"
}

updateAPP()
{
    message="${YELLOW}now push another version of app in github if you push press entre ... ${NC}"
    while true; do
        printf "\r${message}" | pv -qL 15 
        read -s -n 1 key
        echo -en "\033[2K\r"
        if [[ $key = "" ]]; then 
            break
        else
            message="${RED} shold be press entre ${NC}"
        fi
    done

    subject="wating all resource up of app "
    slashProgressBar "$subject" &
    PIDs+=($!)

    previous_version=$(kubectl get pod $pod -n dev -o yaml | grep "image: wil42" | cut -d ':' -f 3)
    check=0

    while true; do
        for pod in $(kubectl get pods -n dev -o jsonpath='{.items[*].metadata.name}'); do
            current_version=$(kubectl get pod $pod -n dev -o yaml | grep "image: wil42" | cut -d ':' -f 3)

            if [ "$current_version" != "$previous_version" ]; then
                check=1
                break
            fi
        done
        if [ "$check" == "1" ]; then
            break
        fi
        sleep 2
    done
    kubectl wait pods -n dev --all --for condition=Ready --timeout=600s > /dev/null 2>&1;
    sleep 2
    terminateProcesses
    echo -en "\033[2K\r"
    printf "\r${GREEN}%-10s Done! 🥇 ${NC}" "APP v2"
    printf "               \n"
    echo -n "see v2 of app in "
    URL=$(kubectl get svc -n dev | awk '{print $4 " " $5}' | sed -n "2p" | cut -d ':' -f 1 | tr " " ":" | awk '{print "http://" $1}')
    printf "${YELLOW}%s $URL ${NC} \n" | pv -qL 10
}

# detect signal if used 
trap terminateScript SIGINT

# run the installations tool
installKubectl
docker_installation
argocd_installation
installHelm
installK3D
setupClaster
argocd_setAPP
updateAPP
terminateProcesses
