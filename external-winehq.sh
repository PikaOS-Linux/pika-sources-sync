#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal WineHQ MIRROR
mkdir -p ./output/external
cd ./output/external

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
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y
    rm -rfv ./*all.deb
else
    echo "i386 Repos are synced"
fi

PPP64=$(cat ppp64.list | tr '\n' ' ')
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y
else
    echo "AMD64 Repos are synced"
    exit 0
fi

# Return to Extranal WineHQ MIRROR
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

apt remove reprepro -y
wget -nv https://launchpad.net/ubuntu/+archive/primary/+files/reprepro_5.3.0-1.4_amd64.deb
apt install -y ./reprepro_5.3.0-1.4_amd64.deb

# Add the new package to the repo
reprepro -C external -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
