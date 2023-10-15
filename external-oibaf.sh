#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Oibaf PPA MIRROR
mkdir -p ./manticoutput
cd ./manticoutput

../ppp https://ppa.pika-os.com/dists/mantic/external/binary-i386/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/mantic/main/binary-i386/Packages.xz https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/ ./ "meson,16,15,spirv,directx-headers,libdrm"
../ppp https://ppa.pika-os.com/dists/mantic/external/binary-amd64/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/mantic/main/binary-amd64/Packages.xz https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/ ./ "meson,16,15,spirv,directx-headers,libdrm"

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
