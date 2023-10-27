#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Get oneAPI pool
mkdir -p ./manticoutput
cd ./manticoutput

../ppp  https://ppa.pika-os.com/dists/pikauwu/oneapi/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/dists/jammy/unified/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/ ./

cd ../

if [ $(ls ./manticoutput/ | wc -l) -lt 1 ]; then
    echo "Mantic repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# Remove currently broken debs
ssh ferreo@direct.pika-os.com 'rm -rfv /srv/www/incoming/intel-gsc_*_amd64.deb '
ssh ferreo@direct.pika-os.com 'rm -rfv /srv/www/incoming/intel-gsc-dev_*_amd64.deb'
ssh ferreo@direct.pika-os.com 'rm -rfv /srv/www/incoming/intel-i915-dkms_*.deb'
ssh ferreo@direct.pika-os.com 'rm -rfv /srv/www/incoming/libdrm*.deb'
ssh ferreo@direct.pika-os.com 'rm -rfv /srv/www/incoming/libmetee*.deb'

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-oneapi /srv/www/incoming/'

# publish the repo
#ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
ssh ferreo@direct.pika-os.com  'aptly publish repo pikauwu-oneapi filesystem:pikarepo:'
