#!/bin/bash

# Check for SSH Directory
if [ ! -d ~/.ssh ]; then
   mkdir -p ~/.ssh/
fi

cat ~/master_ssh_key >> ~/.ssh/authorized_keys
rm ~/master_ssh_key
