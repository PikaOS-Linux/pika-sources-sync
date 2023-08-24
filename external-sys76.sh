#! /bin/bash
set -e

# External Sys76 PPA MIRROR
mkdir -p ./output/rocm
cd ./output/rocm
# Get External Sys76 PPA pool
echo 'deb [trusted=yes] https://ppa.launchpadcontent.net/system76-dev/pre-stable/ubuntu lunar main' | sudo tee /etc/apt/sources.list.d/sys76.list
apt update -y
apt download  -y
# Return to External Sys76 PPA MIRROR
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
