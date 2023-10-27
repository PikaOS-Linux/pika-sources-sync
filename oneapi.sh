#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Get oneAPI pool
mkdir -p ./manticoutput
cd ./manticoutput

../ppp  https://ppa.pika-os.com/dists/pikauwu/oneapi/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/dists/jammy/unified/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/ ./

rm -rfv intel-gsc_*_amd64.deb 
rm -rfv libdrm*.deb 
rm -rfv libmetee*.deb

cd ../

if [ $(ls ./manticoutput/ | wc -l) -lt 1 ]; then
    echo "Mantic repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-oneapi /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
