#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# ROCm MIRROR
mkdir -p ./output/rocm
cd ./output/rocm

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get ROCm pool
echo 'deb [arch=amd64 trusted=yes] https://repo.radeon.com/rocm/apt/5.7 jammy main' | sudo tee /etc/apt/sources.list.d/rocm.list
wget -O - http://repo.radeon.com/rocm/rocm.gpg.key | apt-key add -
apt update -y

PPP=$(../../ppp https://ppa.pika-os.com/dists/lunar/rocm/binary-amd64/Packages http://repo.radeon.com/rocm/apt/5.7/dists/jammy/main/binary-amd64/Packages)

if [ ! -z "$PPP" ]
then
    apt download $PPP -y --target-release 'o=repo.radeon.com'
else
    echo "Repos are synced"
    exit 0
fi

# Return to ROCm MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-rocm /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'
