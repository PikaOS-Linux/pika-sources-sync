#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# output folders
mkdir -p ./manticoutput

cd ./manticoutput

apt install dpkg-sig wget rsync ssh -y

# Get ubuntu main pool
echo "Getting ubuntu main pool 32bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/main/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
echo "Getting ubuntu main pool 64bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/main/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# Get ubuntu multiverse pool
echo "Getting ubuntu multiverse pool 32bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/multiverse/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
echo "Getting ubuntu multiverse pool 64bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/multiverse/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# Get ubuntu restricted pool
echo "Getting ubuntu restricted pool 32bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/restricted/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
echo "Getting ubuntu restricted pool 64bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/restricted/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

# Get ubuntu universe pool
echo "Getting ubuntu universe pool 32bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/universe/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./
echo "Getting ubuntu universe pool 64bit"
../ppp https://ppa.pika-os.com/dists/pikauwu/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/mantic-security/universe/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./

cd ../

if [ $(ls ./manticoutput/ | wc -l) -lt 1 ]; then
echo "Mantic repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-ubuntu /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'