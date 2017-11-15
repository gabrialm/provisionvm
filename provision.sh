#!/bin/bash

# add sudo user to system
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists"
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo $username " has been added to system!" || echo "Failed to add user!"
		usermod -a -G sudo $username
		echo $username " added to sudo group!"
	fi else
	echo "Only root may add a user to the system!"
	exit 2 fi

# disable ssh password based login
grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# create swap file
grep -q "swapfile" /etc/fstab if [ $? -ne 0 ]; then
	fallocate -l 1G /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
	sysctl vm.swappiness=10
	echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
	free -h
	sleep 5
fi
