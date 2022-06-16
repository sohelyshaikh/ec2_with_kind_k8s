#!/bin/bash
kind create cluster --config=kind.yaml
kubectl completion bash > kubecom.sh
echo "ehco "Hello Sohel!! Welcome to K8s" " >> kubecom.sh
mv kubecom.sh .kube/
source $HOME/.kube/kubecom.sh