#! /bin/bash
set -e

apt install tree

# ROCm MIRROR
mkdir -p ./output/rocm
cd ./output/rocm
# Get ROCm pool
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m "http://repo.radeon.com/rocm/apt/5.6/pool/main/"
# Return to ROCm MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

tree

# Sign the packages
#dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
#rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the rocm component exists
#if cat ./output/repo/conf/distributions | grep Components: | grep rocm
#then
#    true
#else
#    sed -i "s#Components:#Components: rocm#" ./output/repo/conf/distributions
#fi

# Add the new package to the repo
#reprepro -C rocm -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
#rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
