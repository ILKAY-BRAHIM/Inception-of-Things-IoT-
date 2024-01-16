#!/bin/bash

echo "[K3S] : installing k3s-server..."
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
sleep 25
echo "deploment apps..."
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
kubectl apply -n default -f /vagrant/app1.yaml
kubectl apply -n default -f /vagrant/app2.yaml
kubectl apply -n default -f /vagrant/app3.yaml

# /usr/local/bin/k3s-uninstall.sh
