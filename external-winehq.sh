#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal WineHQ MIRROR
mkdir -p ./manticoutput
cd ./manticoutput

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get Extranal WineHQ pool
echo 'deb [trusted=yes] https://dl.winehq.org/wine-builds/ubuntu lunar main' | sudo tee /etc/apt/sources.list.d/external.list
apt update -y

# Get i386 packages list
wget https://dl.winehq.org/wine-builds/ubuntu/dists/lunar/main/binary-i386/Packages -O i386-wine-pkg
PKG_I386=$(cat i386-wine-pkg  | grep "Package: " | awk '{print $2}' | sort -u )
touch ppp32.list
for i in $(echo $PKG_I386)
do
    touch /etc/apt/preferences.d/0-external-sync.conf
    echo 'Package': * > /etc/apt/preferences.d/0-external-sync.conf
    echo 'Pin: release o=ppa.pika-os.com' >> /etc/apt/preferences.d/0-external-sync.conf
    echo 'Pin-Priority: 1000' >> /etc/apt/preferences.d/0-external-sync.conf
    apt-cache show $i | grep 'Version:' | cut -d":" -f2 | head -n1 | sed 's/ //g' > $i-pika-i386
    rm -rf /etc/apt/preferences.d/0-external-sync.conf
    apt-cache show $i | grep 'Version:' | cut -d":" -f2 | head -n1 | sed 's/ //g' > $i-external-i386
    if cat $i-pika-i386 | grep "^"$(cat $i-external-i386)"$"
    then
        true
    else
        echo $i >> ppp32.list
    fi
done

# Get amd64 packages list
wget https://dl.winehq.org/wine-builds/ubuntu/dists/lunar/main/binary-amd64/Packages -O amd64-wine-pkg
PKG_AMD64=$(cat amd64-wine-pkg  | grep "Package: " | awk '{print $2}' | sort -u )
touch ppp64.list
for i in $(echo $PKG_AMD64)
do
    touch /etc/apt/preferences.d/0-external-sync.conf
    echo 'Package': * > /etc/apt/preferences.d/0-external-sync.conf
    echo 'Pin: release o=ppa.pika-os.com' >> /etc/apt/preferences.d/0-external-sync.conf
    echo 'Pin-Priority: 1000' >> /etc/apt/preferences.d/0-external-sync.conf
    apt-cache show $i | grep 'Version:' | cut -d":" -f2 | head -n1 | sed 's/ //g' > $i-pika-amd64
    rm -rf /etc/apt/preferences.d/0-external-sync.conf
    apt-cache show $i | grep 'Version:' | cut -d":" -f2 | head -n1 | sed 's/ //g' > $i-external-amd64
    if cat $i-pika-amd64 | grep "^"$(cat $i-external-amd64)"$"
    then
        true
    else
        echo $i >> ppp64.list
    fi
done

PPP32=$(cat ppp32.list | tr '\n' ' ')
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y --target-release 'o=dl.winehq.org'
    rm -rfv ./*all.deb
else
    echo "i386 Repos are synced"
fi

PPP64=$(cat ppp64.list | tr '\n' ' ')
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --target-release 'o=dl.winehq.org'
else
    echo "AMD64 Repos are synced"
fi

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
