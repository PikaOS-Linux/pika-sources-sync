#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Oibaf PPA MIRROR
mkdir -p ./output
cd ./output

../ppp https://ppa.pika-os.com/dists/lunar/external/binary-i386/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/lunar/main/binary-i386/Packages.xz https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/ ./ "meson,16,15,spirv,directx-headers,libdrm"
../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/lunar/main/binary-amd64/Packages.xz https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/ ./ "meson,16,15,spirv,directx-headers,libdrm"

cd ../

if [ $(ls ./output/ | wc -l) -lt 1 ]; then
    echo "Lunar repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'
