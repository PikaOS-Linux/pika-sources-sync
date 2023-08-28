#! /bin/bash
set -e


SHOULD_EXIT=0

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

# Get Extranal Wasta Cinnamon PPA pool
echo 'deb [arch=amd64 trusted=yes] https://ppa.launchpadcontent.net/wasta-linux/cinnamon-testing/ubuntu jammy main' | sudo tee /etc/apt/sources.list.d/external.list
apt update -y --allow-unauthenticated

WASTA_PPP=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/wasta-linux/cinnamon-testing/ubuntu/dists/jammy/main/binary-amd64/Packages.xz | tr ' ' '\n' | grep -E 'mintinstall|warpinator|webapp-manager|mint-common|mint-translations' | tr '\n' ' ')

if [ ! -z "$WASTA_PPP" ]
then
    apt download $WASTA_PPP -y
else
    echo "Wasta Repos are synced"
    export SHOULD_EXIT=1
fi

rm -rf /etc/apt/sources.list.d/external.list

# Get Extranal Papirus PPA pool
echo 'deb [arch=amd64 trusted=yes] https://ppa.launchpadcontent.net/papirus/papirus/ubuntu lunar main' | sudo tee /etc/apt/sources.list.d/external.list
apt update -y --allow-unauthenticated

PAPIRUS_PPP=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/papirus/papirus/ubuntu/dists/lunar/main/binary-amd64/Packages.xz)
if [ ! -z "$PAPIRUS_PPP" ]
then
    apt download $PAPIRUS_PPP -y
else
    echo "Papirus Repos are synced"
    if [[ $SHOULD_EXIT == 1 ]]
    then
        exit 0
    fi
fi

# Return to Extranal MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# Sign the packages
dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the external component exists
if cat ./output/repo/conf/distributions | grep Components: | grep external
then
    true
else
    sed -i "s#Components:#Components: external#" ./output/repo/conf/distributions
fi

# Add the new package to the repo
reprepro -C external -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
