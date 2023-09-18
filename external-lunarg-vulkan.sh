#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# LunarG Vulkan SDK MIRROR
mkdir -p ./output/lunarg
cd ./output/lunarg

../ppp https://ppa.pika-os.com/dists/lunar/external/binary-i386/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-amd64/Packages https://packages.lunarg.com/vulkan/ ./

../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-amd64/Packages https://packages.lunarg.com/vulkan/ ./

cd ../

if [ $(ls ./output/ | wc -l) -lt 1 ]; then
    echo "Lunar repos are synced"
fi

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'
