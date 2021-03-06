#!/bin/bash

# Make apt-get be fully non-interactive
export DEBIAN_FRONTEND=noninteractive

# Turn on logging to disk
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
pkill -USR1 systemd-journal # use 'journalctl --flush' once available

# Full system update/upgrade according to shell-etc settings
apt update
apt install -y -q --force-yes apt-transport-https

wget https://raw.githubusercontent.com/hashbang/shell-etc/master/apt/sources.list -O /etc/apt/sources.list
wget https://raw.githubusercontent.com/hashbang/shell-etc/master/apt/preferences -O /etc/apt/preferences
wget https://raw.githubusercontent.com/hashbang/shell-etc/master/packages.txt -O /etc/packages.txt

apt update
apt-cache dumpavail | dpkg --update-avail
dpkg --clear-selections
dpkg --set-selections < /etc/packages.txt
apt-get dselect-upgrade -q -y
apt upgrade
aptitude purge -y -q ~c


# Point etckeeper at shell-etc repo and sync all configs
cd /etc
rm -rf .git
git init
git remote add origin https://github.com/hashbang/shell-etc.git
git fetch origin master
git reset --hard origin/master
git clean -d -f
etckeeper init # Apply the correct file permissions

# Take /etc/default/grub into account
update-grub


# Disable users knowing about other users
for f in /var/run/utmp /var/log/wtmp /var/log/lastlog; do
    chmod 0660 "$f"               # Not readable by default users
    setfacl -m 'group:adm:r' "$f" # Readable by the adm group
done

reboot
