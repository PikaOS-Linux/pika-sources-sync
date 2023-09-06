#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Mozilla PPA MIRROR
mkdir -p ./output/external
cd ./output/external

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get Extranal Mozilla PPA pool
echo 'deb [trusted=yes] https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu lunar main' | sudo tee /etc/apt/sources.list.d/external.list
apt update -y --allow-unauthenticated

PPP=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/dists/lunar/main/binary-amd64/Packages.xz)
touch /etc/apt/preferences.d/0-external.conf
echo 'Package: *' > /etc/apt/preferences.d/0-external.conf
echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/0-external.conf
echo 'Pin-Priority: 2001' >> /etc/apt/preferences.d/0-external.conf
if [ ! -z "$PPP" ]
then
    apt download $PPP -y --target-release 'o=LP-PPA-mozillateam'
else
    echo "Repos are synced"
    exit 0
fi

# Return to Extranal Mozilla PPA MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'