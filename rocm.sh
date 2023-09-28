#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Get ROCm pool
mkdir -p ./output
cd ./output

../ppp  https://ppa.pika-os.com/dists/lunar/rocm/binary-amd64/Packages http://repo.radeon.com/rocm/apt/5.7/dists/jammy/main/binary-amd64/Packages http://repo.radeon.com/rocm/apt/5.7/ ./

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

