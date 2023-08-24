#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

# ROCm MIRROR
mkdir -p ./output/rocm
cd ./output/rocm

# temp
apt update
apt upgrade -y
# end of temp

#Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

# Get ROCm pool
echo 'deb [arch=amd64 trusted=yes] https://repo.radeon.com/rocm/apt/5.6 jammy main' | sudo tee /etc/apt/sources.list.d/rocm.list
wget -O - http://repo.radeon.com/rocm/rocm.gpg.key | apt-key add -
apt update -y

apt download $(../../ppp https://ppa.pika-os.com/dists/lunar/rocm/binary-amd64/Packages http://repo.radeon.com/rocm/apt/5.6/dists/jammy/main/binary-amd64/Packages  | tr '\n' ' ') -y
# Return to ROCm MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# Sign the packages
dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the rocm component exists
if cat ./output/repo/conf/distributions | grep Components: | grep rocm
then
    true
else
    sed -i "s#Components:#Components: rocm#" ./output/repo/conf/distributions
fi

# Add the new package to the repo
reprepro -C rocm -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
