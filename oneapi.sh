#! /bin/bash
set -e

ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm intel-media-va-driver-non-free'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-drm2' 
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-glx2' 
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-wayland2'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-x11-2'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva2'

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Get oneAPI pool
mkdir -p ./manticoutput
cd ./manticoutput

../ppp  https://ppa.pika-os.com/dists/pikauwu/rocm/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/dists/jammy/unified/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/ ./

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
ssh ferreo@direct.pika-os.com  /bin/bash << EOF
rm -rfv /srv/www/incoming/*va*.deb
EOF

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-rocm /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
