#!/bin/bash
set -ex
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
curl -sLo kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.19.11@sha256:07db187ae84b4b7de440a73886f008cf903fcf5764ba8106a9fd5243d6f32729
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
  - containerPort: 30001
    hostPort: 30001" > kind.yaml
aws ecr get-login-password --region us-east-1 | docker login -u AWS --password-stdin 700066115436.dkr.ecr.us-east-1.amazonaws.com