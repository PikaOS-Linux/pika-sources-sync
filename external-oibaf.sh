#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Extranal Oibaf PPA MIRROR
mkdir -p ./output/external
cd ./output/external

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get Extranal Oibaf PPA pool
echo 'deb [trusted=yes] https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu  lunar main' | sudo tee /etc/apt/sources.list.d/external.list

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-i386/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/lunar/main/binary-i386/Packages.xz | tr ' ' '\n' | grep -E 'meson|16|15|spirv|directx-headers|libdrm' | tr '\n' ' ')
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP_32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y --target-release 'o=LP-PPA-oibaf-graphics-drivers'
    rm -rfv ./*all.deb
else
    echo "i386 Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/dists/lunar/main/binary-amd64/Packages.xz | tr ' ' '\n' | grep -E 'meson|16|15|spirv|directx-headers|libdrm' | tr '\n' ' ')
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --target-release 'o=LP-PPA-oibaf-graphics-drivers'
else
    echo "AMD64 Repos are synced"
    exit 0
fi

# Return to Extranal Oibaf PPA MIRROR
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
