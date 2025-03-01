#!/bin/bash

# Set up Keys and Install Falco
  curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | sudo tee /etc/apt/sources.list.d/falcosecurity.list >/dev/null && \
  sudo apt-get update -qqy && \
  sudo apt-get install -yqq --no-install-recommends dkms make linux-headers-$(uname -r) falco

kubectl create ns falco-test

# Install deployment 1 to compromise nc activities
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zany-smile
  namespace: falco-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zany-smile
  template:
    metadata:
      labels:
        app: zany-smile
    spec:
      containers:
      - name: zany-smile
        image: alpine:3.14
        command: ["sh", "-c", "while true; do nc -e /bin/sh -l -p 1234; sleep 5; done"]
EOF


# Install deployment 2 to compromise AWS creds
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: monstrous-kraken
  namespace: falco-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: monstrous-kraken
  template:
    metadata:
      labels:
        app: monstrous-kraken
    spec:
      containers:
      - name: monstrous-kraken
        image: ubuntu
        command:
        - sh
        - -c
        - |
          mkdir -p /root/.aws
          head -c 14 /dev/urandom | base64 > /root/.aws/credentials
          while true; do find /root -name .aws/credentials; sleep 5; done
EOF

# Install other deployments that run normally
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: starry-shadow
  name: starry-shadow
  namespace: falco-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: starry-shadow
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: starry-shadow
    spec:
      containers:
      - command:
        - sleep
        - 1d
        image: alpine:3.14
        name: alpine
EOF


cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: firedrake-champion
  name: firedrake-champion
  namespace: falco-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: firedrake-champion
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: firedrake-champion
    spec:
      containers:
      - image: nginx
        name: nginx
EOF


sleep 5
touch /tmp/finished