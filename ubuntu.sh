#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# output folders
mkdir -p ./output/incoming

cd ./output

# temp
apt update
apt upgrade -y
# end of temp

apt install wget rsync ssh -y

# Get ubuntu main pool
echo "Getting ubuntu main pool 32bit"
../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming
echo "Getting ubuntu main pool 64bit"
../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/main/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming

# Get ubuntu multiverse pool
# echo "Getting ubuntu multiverse pool 32bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming
# echo "Getting ubuntu multiverse pool 64bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/multiverse/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming

# Get ubuntu restricted pool
# echo "Getting ubuntu restricted pool 32bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming
# echo "Getting ubuntu restricted pool 64bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/restricted/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming

# Get ubuntu universe pool
# echo "Getting ubuntu universe pool 32bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-i386/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-i386/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming
# echo "Getting ubuntu universe pool 64bit"
# ../ppp https://ppa.pika-os.com/dists/lunar/ubuntu/binary-amd64/Packages.gz http://archive.ubuntu.com/ubuntu/dists/lunar/universe/binary-amd64/Packages.xz http://archive.ubuntu.com/ubuntu/ ./incoming

if [ $(ls ./output/ | wc -l) -lt 1 ]; then
echo "Repos are synced"
    exit 0
fi

# send debs to server
rsync -azP ./output/incoming/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-ubuntu /srv/www/incoming'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish repo -batch -skip-contents -force-overwrite -component=,,,, pika-a
mdgpu pika-external pika-main pika-rocm pika-ubuntu filesystem:pikarepo:'
