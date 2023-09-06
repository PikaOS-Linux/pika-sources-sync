#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal XtraDEB PPA MIRROR
mkdir -p ./output/external
cd ./output/external

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get Extranal XtraDEB PPA pool
echo 'deb [arch=amd64 trusted=yes] https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu lunar main' | sudo tee /etc/apt/sources.list.d/external.list
apt update -y --allow-unauthenticated

PPP=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu/dists/lunar/main/binary-amd64/Packages.xz | tr ' ' '\n' | grep chromium | tr '\n' ' ')

if [ ! -z "$PPP" ]
then
    apt download $PPP -y --target-release 'o=LP-PPA-xtradeb-apps'
else
    echo "Repos are synced"
    exit 0
fi

# Return to Extranal XtraDEB PPA MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'