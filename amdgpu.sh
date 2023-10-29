#! /bin/bash
set -e

# AMDGPU MIRROR
mkdir -p ./outputpika/amdgpu
cd ./outputpika/amdgpu
# amdgpu drm dir
mkdir -p ./libd
cd ./libd
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/main/libd/
# Return to AMDGPU MIRROR
cd ../
# amdgpu mesa dir (depends only)
mkdir -p ./mesa
cd ./mesa
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/main/m/mesa-amdgpu/
# Return to AMDGPU MIRROR
cd ../
# amdgpu wayland dir (depends only)
mkdir -p ./wayland-amdgpu
cd ./wayland-amdgpu
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/main/w/wayland-amdgpu/
# Return to AMDGPU MIRROR
cd ../
# amdgpu wayland protocols dir (depends only)
mkdir -p ./wayland-protocols-amdgpu
cd ./wayland-protocols-amdgpu
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m http://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/main/w/wayland-protocols-amdgpu/
# Return to AMDGPU MIRROR
cd ../
# amdgpu proprietary dir
mkdir -p ./proprietary
cd ./proprietary
wget --recursive --no-parent -R "*20.04*.deb" -A "*" -m https://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/proprietary/
# Return to AMDGPU MIRROR
cd ../
# amdgpu-dkms-firmware dir
mkdir -p ./amdgpu-dkms-firmware
cd ./amdgpu-dkms-firmware
wget http://repo.radeon.com/amdgpu/23.20/amdgpu/ubuntu/pool/main/a/amdgpu-dkms/amdgpu-dkms-firmware_6.2.4.50700-1646729.22.04_all.deb
# Return to AMDGPU MIRROR
cd ../
mkdir -p ./outputpika
mkdir -p ./outputpika-tmp
find . -name \*.deb -exec cp -vf {} ./outputpika-tmp \;

cd ./outputpika-tmp
for i in ./*.deb
do
    mkdir $i-tmp
    dpkg-deb -R $i $i-tmp
    cat $i-tmp/DEBIAN/control | grep Version: | head -n1 | cut -d":" -f2- | tr -d ' ' > $i-version
    sed -i "s#$(cat $i-version)#$(cat $i-version)-pika$(date +"%Y%m%d").pikauwu1#g" $i-tmp/DEBIAN/control
    dpkg-deb -b $i-tmp $i-"$(date +"%Y%m%d")"-pika-pikauwu1-fixed.deb
done
cd ../
mv -v ./outputpika-tmp/*-fixed.deb ./outputpika/

# send debs to server
rsync -azP ./outputpika/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-amdgpu /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
