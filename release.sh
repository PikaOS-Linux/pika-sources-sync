#! /bin/bash

# Sign the packages
#dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
#rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

mkdir -p ./output/amdgpu
cd ./output/amdgpu
wget -r -np -nH --cut-dirs=3 -R index.html http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool
ls

# Add the new package to the repo
#reprepro -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
#rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
