#! /bin/bash
set -e

ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm intel-media-va-driver-non-free'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-drm2' 
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-glx2' 
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-wayland2'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-x11-2'
ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva2'

# Give correct perms to Apt version checker
chmod 755 ./ppp

# Get oneAPI pool
mkdir -p ./manticoutput-tmp
cd ./manticoutput-tmp

../ppp  https://ppa.pika-os.com/dists/pikauwu/rocm/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/dists/jammy/unified/binary-amd64/Packages https://repositories.intel.com/gpu/ubuntu/ ./

rm -rfv ./intel-i915-dkms_*.deb
rm -rfv ./libdrm*.deb
rm -rfv ./*va*.deb
rm -rfv ./intel-gsc*.deb
rm -rfv ./libmetee*.deb
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy unified" | tee /etc/apt/sources.list.d/intel-gpu-jammy.list
apt update
apt download -y intel-gsc intel-gsc-dev libmetee-dev libmetee

if [ $(ls ./ | wc -l) -lt 1 ]; then
    echo "Mantic repos are synced"
    exit 0
fi

for i in ./*.deb
do
    mkdir $i-tmp
    dpkg-deb -R $i $i-tmp
    cat $i-tmp/DEBIAN/control | grep Version: | head -n1 | cut -d":" -f2- | tr -d ' ' > $i-version
    sed -i "s#$(cat $i-version)#$(cat $i-version)-pika$(date +"%Y%m%d").pikauwu1#g" $i-tmp/DEBIAN/control
    sed -e s"#(=#(>=#"g -i $i-tmp/DEBIAN/control
    dpkg-deb -b $i-tmp $i-"$(date +"%Y%m%d")"-pika-pikauwu1-fixed.deb
done

cd ../

mkdir -p ./manticoutput/
mv -v ./manticoutput-tmp/*-fixed.deb ./manticoutput/

# send debs to server
rsync -azP ./manticoutput/ ferreo@direct.pika-os.com:/srv/www/incoming/

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-rocm /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
