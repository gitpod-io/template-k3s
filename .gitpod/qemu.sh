#!/bin/bash

set -xeuo pipefail

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

waitapt
sudo apt update -y
sudo apt install qemu qemu-system-x86 linux-image-generic -y

script_dirname="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
outdir="${script_dirname}/_output"

sudo qemu-system-x86_64 -kernel "/boot/vmlinuz" \
-boot c -m 2049M -hda "${outdir}/rootfs/jammy-server-cloudimg-amd64.img" \
-net user \
-smp 8 \
-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
-nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::6443-:6443 \
-serial mon:stdio -display none
