#! /bin/bash
set -e

# AMDGPU MIRROR
mkdir -p ./output/amdgpu
cd ./output/amdgpu
# amdgpu drm dir
mkdir -p ./libd
cd ./libd
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/main/libd/
# Return to AMDGPU MIRROR
cd ../
# amdgpu mesa dir (depends only)
mkdir -p ./mesa
cd ./mesa
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/main/m/mesa-amdgpu/
# Return to AMDGPU MIRROR
cd ../
# amdgpu proprietary dir
mkdir -p ./proprietary
cd ./proprietary
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m https://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/proprietary/
# Return to AMDGPU MIRROR
cd ../
# amdgpu-dkms-firmware dir
mkdir -p ./amdgpu-dkms-firmware
cd ./amdgpu-dkms-firmware
wget http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/main/a/amdgpu-dkms/amdgpu-dkms-firmware_6.0.5.50503-1620033.20.04_all.deb
# Return to AMDGPU MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \;

# Sign the packages
dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Check if the amdgpu component exists
if cat ./output/repo/conf/distributions | grep Components: | grep amdgpu
then
    true
else
    sed -i "s#Components:#Components: amdgpu#" ./output/repo/conf/distributions
fi

apt remove reprepro -y
wget -nv https://launchpad.net/ubuntu/+archive/primary/+files/reprepro_5.3.0-1.4_amd64.deb
apt install -y ./reprepro_5.3.0-1.4_amd64.deb

# Add the new package to the repo
reprepro -C amdgpu -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
