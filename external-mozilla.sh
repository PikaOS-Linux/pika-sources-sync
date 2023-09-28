#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Mozilla PPA MIRROR
mkdir -p ./output
cd ./output

../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/dists/lunar/main/binary-amd64/Packages.xz https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/ ./

cd ../

if [ $(ls ./output/ | wc -l) -lt 1 ]; then
    echo "Lunar repos are synced"
    exit 0
fi
