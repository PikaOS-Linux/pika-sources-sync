#! /bin/bash
set -e

# AMDGPU MIRROR
mkdir -p ./output/amdgpu
cd ./output/amdgpu
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
mkdir -p ./output
mkdir -p ./output-tmp
find . -name \*.deb -exec cp -vf {} ./output-tmp \;

cd ./output-tmp
for i in ./*.deb
do
    mkdir $i-tmp
    dpkg-deb -R $i $i-tmp
    cat $i-tmp/DEBIAN/control | grep Version: | head -n1 | cut -d":" -f2- | tr -d ' ' > $i-version
    sed -i "s#$(cat $i-version)#$(cat $i-version)-pika$(date +"%Y%m%d").lunar3#g" $i-tmp/DEBIAN/control
    dpkg-deb -b $i-tmp $i-fixed.deb
done
cd ../
mv -v ./output-tmp/*-fixed.deb ./output/

# send debs to server
rsync -azP ./output/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pika-amdgpu /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'
