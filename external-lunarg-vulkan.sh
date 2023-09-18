#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# LunarG Vulkan SDK MIRROR
mkdir -p ./output/lunarg
cd ./output/lunarg

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get LunarG Vulkan SDK pool
echo 'deb [rusted=yes] deb https://packages.lunarg.com/vulkan jammy main' | sudo tee /etc/apt/sources.list.d/lunarg-vulkan.list
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
apt update -y

PPP32=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-i386/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-i386/Packages)
if [ ! -z "$PPP32" ]
then
    dpkg --add-architecture i386
    apt update -o APT::Architecture="i386" -o APT::Architectures="i386" -y --allow-unauthenticated 
    apt download $PPP32 -o APT::Architecture="i386" -o APT::Architectures="i386" -y --target-release 'o=vulkan.lunarg.com'
    rm -rfv ./*all.deb
else
    echo "i386 Repos are synced"
fi

PPP64=$(../../ppp https://ppa.pika-os.com/dists/lunar/external/binary-amd64/Packages https://packages.lunarg.com/vulkan/dists/jammy/main/binary-amd64/Packages)
if [ ! -z "$PPP64" ]
then
    apt update -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --allow-unauthenticated 
    apt download $PPP64 -o APT::Architecture="amd64" -o APT::Architectures="amd64" -y --target-release 'o=vulkan.lunarg.com'
else
    echo "AMD64 Repos are synced"
    exit 0
fi

# Return to LunarG Vulkan SDK MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-external /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'
