#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# output folders
mkdir -p ./output/output
cd ./output/output

# temp
apt update
apt upgrade -y
# end of temp

apt install dpkg-sig wget rsync ssh -y

# Get ubuntu main pool
echo "Getting ubuntu main pool 32bit"
../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
rm -rfv ./*all.deb
echo "Getting ubuntu main pool 64bit"
../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# # Get ubuntu multiverse pool
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
# rm -rfv ./*all.deb
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# # Get ubuntu restricted pool
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
# rm -rfv ./*all.deb
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# # Get ubuntu universe pool
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
# rm -rfv ./*all.deb
# ../../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

cd ../

if [ ! -e ./output/*.deb ]; then
echo "Repos are synced"
    exit 0
fi

# Sign the packages
../ppp sign ./output/

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

# Add the new packages to the repo
reprepro -C ubuntu -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
