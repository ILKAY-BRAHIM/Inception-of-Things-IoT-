#!/bin/bash

echo Installing k3s-agent...
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$(sudo cat /vagrant/node-token) sh -
sleep 10
