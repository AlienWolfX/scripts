#!/bin/sh

# Author: Allen Gabrielle Cruiz
# Github: https://www.github.com/AlienWolfX
# Date: 2024-19-05
# Version: 1.0
# Description: This script is used to install the required packages for IT112 Project

set -e

# Preparing the system for installation
sudo apt-get update && sudo apt-get upgrade -y

# Lab 1: Installing Apache2
sudo apt install apache2 -y
if sudo systemctl status apache2 | grep -q 'running'; then
    echo -e "\e[32mApache2 is running\e[0m"
else
    echo -e "\e[31mApache2 is not running\e[0m"
    exit 1
fi
sleep 2

# Lab 2: 
sudo apt install openssh-server -y
sudo systemctl restart sshd.service
sleep 2

# Lab 3:
sudo apt install nfs-kernel-server -y

# Creating the directories for the NFS
sudo mkdir -p /srv/nfs4/backups
sudo mkdir -p /srv/nfs4/www

# Binding the directories to the NFS
sudo mount --bind /opt/backups /srv/nfs4/backups
sudo mount --bind /var/www /srv/nfs4/www

# Appending the directories to the fstab
echo "/opt/backups /srv/nfs4/backups  none   bind   0   0" | sudo tee -a /etc/fstab
echo "/var/www     /srv/nfs4/www      none   bind   0   0" | sudo tee -a /etc/fstab

# Exportfs
third=$(hostname -I | cut -d'.' -f3)
ip_prefix="192.168.$third"

# Prepare the lines with the correct IP part
# Pagkuha sa ip_prefix run hostname -I for example ang result niya is 192.168.2.1 kuhaa ang 2 then ibutang as 192.168.2.0/24
lines="/srv/nfs4         $ip_prefix.0/24(rw,sync,no_subtree_check,crossmnt,fsid=0)
/srv/nfs4/backups $ip_prefix.0/24(ro,sync,no_subtree_check) $ip_prefix.3(rw,sync,no_subtree_check)
/srv/nfs4/www     $ip_prefix.20(rw,sync,no_subtree_check)"

# Append the lines to the /etc/exports file if they don't already exist
for line in "$lines"; do
    grep -qxF "$line" /etc/exports || echo "$line" | sudo tee -a /etc/exports
done

sudo exportfs -ar
sudo exportfs -v

# Firewall
sudo ufw allow from $ip_prefix.0/24 to any port nfs
sudo ufw status

# Web
# wget https://github.com/AlienWolfX/mifi_webui/blob/main/web.7z
# sudo mkdir -p /var/www/web
# sudo unzip IT112.zip -d /var/www/web
echo "All done :)"