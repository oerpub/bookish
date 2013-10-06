#!/usr/bin/env bash

# Get root up in here
sudo su

# Just a simple way of checking if you we need to install everything
if [ ! -d "/var/www" ]
then
    # Update and begin installing some utility tools
    apt-get -y update
    apt-get install -y python-software-properties git curl build-essential apache2

    # vboxfs doesn't support sendfile, turn that off
    echo "EnableSendfile off" >> /etc/apache2/apache2.conf

    # Build latest node.js from source
    cd /tmp
    git clone -b v0.10.11-release https://github.com/joyent/node.git
    cd node
    ./configure
    make
    make install

    # Symlink our host www to the guest /var/www folder
    sudo rm -rf /var/www
    sudo ln -s /vagrant/ /var/www
fi

cd /vagrant
npm install
