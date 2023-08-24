#! /bin/bash
set -e

# Oibaf Graphics MIRROR
mkdir -p ./output/launchpad-oibaf-graphics
cd ./output/launchpad-oibaf-graphics
# launchpad-oibaf-graphics directx-headers dir
mkdir -p ./directx-headers
cd ./directx-headers
wget --recursive --no-parent -R "*arm64.deb,*armhf.deb,*ppc64el.deb,*s390x.deb" -A "*oibaf~l*" -m https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/pool/main/d/directx-headers/
# Return to Oibaf Graphics MIRROR
cd ../
# launchpad-oibaf-graphics drm dir
mkdir -p ./drm
cd ./drm
wget --recursive --no-parent -R "*arm64.deb,*armhf.deb,*ppc64el.deb,*s390x.deb" -A "*oibaf~l*" -m https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/pool/main/libd/libdrm/
# Return to Oibaf Graphics MIRROR
cd ../
# launchpad-oibaf-graphics meson dir
mkdir -p ./meson
cd ./meson
wget --recursive --no-parent -R "*arm64.deb,*armhf.deb,*ppc64el.deb,*s390x.deb" -A "*oibaf~l*" -m https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/pool/main/m/meson/
# Return to Oibaf Graphics MIRROR
cd ../
# launchpad-oibaf-graphics spirv dir
mkdir -p ./spirv 
cd ./spirv 
wget --recursive --no-parent -R "*arm64.deb,*armhf.deb,*ppc64el.deb,*s390x.deb" -A "*oibaf~l*" -m https://ppa.launchpadcontent.net/oibaf/graphics-drivers/ubuntu/pool/main/s/
# Return to Oibaf Graphics MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# Sign the packages
dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the launchpad component exists
if cat ./output/repo/conf/distributions | grep Components: | grep launchpad
then
    true
else
    sed -i "s#Components:#Components: launchpad#" ./output/repo/conf/distributions
fi

# Add the new package to the repo
reprepro -C launchpad -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
