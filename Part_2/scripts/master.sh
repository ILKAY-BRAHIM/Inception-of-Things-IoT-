#!/bin/bash

echo "[K3S] : installing k3s-server..."
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
# sleep 25
# echo "hi......"
# sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# sudo cat /var/lib/rancher/k3s/server/node-token
# kubectl apply -n default -f /vagrant/app1.yaml
# kubectl apply -n default -f /vagrant/ingress.yaml
# sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/
# sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/

# /usr/local/bin/k3s-uninstall.sh
