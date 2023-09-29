#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal lunarg PPA MIRROR
mkdir -p ./manticoutput
cd ./manticoutput

../ppp https://ppa.pika-os.com/dists/pikauwu/external/binary-i386/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-i386/Packages https://packages.lunarg.com/vulkan/ ./

../ppp https://ppa.pika-os.com/dists/pikauwu/external/binary-amd64/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-amd64/Packages https://packages.lunarg.com/vulkan/ ./

cd ../

if [ $(ls ./manticoutput/ | wc -l) -lt 1 ]; then
    echo "Mantic repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
