#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Steam MIRROR
mkdir -p ./manticoutput
cd ./manticoutput

../ppp https://ppa.pika-os.com/dists/mantic/external/binary-i386/Packages https://repo.steampowered.com/steam/dists/stable/steam/binary-i386/Packages https://repo.steampowered.com/steam/ ./
../ppp https://ppa.pika-os.com/dists/mantic/external/binary-amd64/Packages https://repo.steampowered.com/steam/dists/stable/steam/binary-amd64/Packages https://repo.steampowered.com/steam/ ./

cd ../

if [ $(ls ./manticoutput/ | wc -l) -lt 1 ]; then
    echo "Mantic repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external-mantic /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite mantic filesystem:pikarepo:'
