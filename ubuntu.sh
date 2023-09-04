#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# ubuntu MIRROR
mkdir -p ./output/ubuntu
cd ./output/ubuntu

# temp
apt update
apt upgrade -y
# end of temp

apt install dpkg-sig wget rsync -y

# Get ubuntu main pool

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-i386/Packages.xz)
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y
    rm -rfv ./*all.deb
else
    echo "i386 Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-amd64/Packages.xz)
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y
else
    echo "AMD64 Repos are synced"
    exit 0
fi

# Get ubuntu multiverse pool

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-i386/Packages.xz)
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y
    rm -rfv ./*all.deb
else
    echo "i386 multiverse Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-amd64/Packages.xz)
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y
else
    echo "AMD64 multiverse Repos are synced"
    exit 0
fi

# Get ubuntu restricted pool

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-i386/Packages.xz)
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y
    rm -rfv ./*all.deb
else
    echo "i386 restricted Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-amd64/Packages.xz)
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y
else
    echo "AMD64 restricted Repos are synced"
    exit 0
fi

# Get ubuntu universe pool

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-i386/Packages.xz)
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y
    rm -rfv ./*all.deb
else
    echo "i386 universe Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-amd64/Packages.xz)
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y
else
    echo "AMD64 universe Repos are synced"
    exit 0
fi

# Return to ubuntu MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# Sign the packages
for f in ./output/*.deb; do dpkg-sig --sign builder "$f"; done

# Pull down existing ppa repo db files etc
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the ubuntu component exists
if cat ./output/repo/conf/distributions | grep Components: | grep ubuntu
then
    true
else
    sed -i "s#Components:#Components: ubuntu#" ./output/repo/conf/distributions
fi

apt remove reprepro -y
wget -nv https://launchpad.net/ubuntu/+archive/primary/+files/reprepro_5.3.0-1.4_amd64.deb
apt install -y ./reprepro_5.3.0-1.4_amd64.deb

# Add the new package to the repo
for f in ./output/*.deb; do reprepro -C ubuntu -V --basedir ./output/repo/ includedeb lunar ./output/*.deb "$f"; done

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
