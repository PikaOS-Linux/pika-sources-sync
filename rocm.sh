#! /bin/bash
set -e

# ROCm MIRROR
mkdir -p ./output/rocm
cd ./output/rocm

# temp
apt update
apt upgrade -y
# end of temp

# Get package list from ROCm Pool
wget http://repo.radeon.com/rocm/apt/5.6/dists/jammy/main/binary-amd64/Packages
# Get rid of Pika sources to prevent conflicts
rm -rf /etc/apt/sources.list.d/pika*
rm -rf  /etc/apt/preferences.d/*pika*

for i in $(cat ./Packages | grep "Package: " | awk '{print $2}')
do
    # Get ROCm pool from pika
    echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/pika-keyring.gpg.key] https://ppa.pika-os.com/ lunar rocm' | sudo tee /etc/apt/sources.list.d/rocm-pika.list
    apt update -y
    apt-cache show $i | grep Version: > ./$i-pika.txt
    rm -rf /etc/apt/sources.list.d/rocm-pika.list
    # Get ROCm pool
    echo 'deb [arch=amd64 trusted=yes] https://repo.radeon.com/rocm/apt/5.6 jammy main' | sudo tee /etc/apt/sources.list.d/rocm.list
    apt update -y
    apt-cache show $i | grep Version: > ./$i-repo.txt
    if [[ $(cat ./$i-pika.txt ) == $(cat ./$i-repo.txt ) ]]
    then
        true
    else
        echo $i >> pkglist.txt
    fi
done
apt download $(cat ./pkglist.txt | tr '\n' ' ') -y
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
