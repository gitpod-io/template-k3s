#!/bin/bash

script_dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
rootfslock="${script_dirname}/_output/rootfs/rootfs-ready.lock"
k3sreadylock="${script_dirname}/_output/rootfs/k3s-ready.lock"

if test -f "${k3sreadylock}"; then
    exit 0
fi

cd $script_dirname

function waitssh() {
  while ! nc -z 127.0.0.1 2222; do   
    sleep 0.1
  done
  ./ssh.sh "whoami" &>/dev/null
  if [ $? -ne 0 ]; then
    sleep 1
    waitssh
  fi
}

function waitapt() {
  i=0
  tput sc
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
      case $(($i % 4)) in
          0 ) j="-" ;;
          1 ) j="\\" ;;
          2 ) j="|" ;;
          3 ) j="/" ;;
      esac
      tput rc
      echo -en "\r[$j] Waiting for other software managers to finish..." 
      sleep 0.5
      ((i=i+1))
  done
}

function waitrootfs() {
  while ! test -f "${rootfslock}"; do
    sleep 0.1
  done
}

echo "🔥 Installing everything, this will be done only one time per workspace."

echo "Waiting for the rootfs to become available, it can take a while, open the terminal #2 for progress"
waitrootfs
echo "✅ rootfs available"

echo "Wait for apt lock to end"
waitapt
apt install netcat
echo "✅ no more apt lock"

echo "Waiting for the ssh server to become available, it can take a while, after this k3s is getting installed"
waitssh
echo "✅ ssh server available"

./ssh.sh "curl -sfL https://get.k3s.io | sh -"

mkdir -p ~/.kube
./scp.sh root@127.0.0.1:/etc/rancher/k3s/k3s.yaml ~/.kube/config

echo "✅ k3s server is ready"
kubectl get pods --all-namespaces

touch "${k3sreadylock}"
