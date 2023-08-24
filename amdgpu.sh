#! /bin/bash
set -e

# Sign the packages
#dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
#rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

apt install -y tree

# AMDGPU MIRROR
mkdir -p ./output/amdgpu
cd ./output/amdgpu
# amdgpu-dkms-firmware dir
mkdir -p ./amdgpu-dkms-firmware
cd ./amdgpu-dkms-firmware
wget http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/main/a/amdgpu-dkms/amdgpu-dkms_6.0.5.50503-1620033.20.04_all.deb
# Retrun to AMDGPU MIRROR
cd ../
# amdgpu drm dir
mkdir -p ./libd
cd ./libd
wget --recursive --no-parent -m http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/main/libd/
# Retrun to AMDGPU MIRROR
cd ../
# amdgpu proprietary dir
mkdir -p ./proprietary
cd ./proprietary
wget --recursive --no-parent -m https://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool/proprietary/
# Retrun to AMDGPU MIRROR
cd ../
mkdir -p ./output
find . -name \*.deb -exec cp -vf {} ./output \
# Check final result
tree

# Add the new package to the repo
#reprepro -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
#rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
