# Sign the packages
#dpkg-sig --sign builder ./output/*.deb

# Pull down existing ppa repo db files etc
#rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

rsync -azP --exclude '20.04*.deb' http://repo.radeon.com/amdgpu/5.5.3/ubuntu/pool ./output/repo

# Add the new package to the repo
#reprepro -V --basedir ./output/repo/ includedeb lunar ./output/*.deb

# Push the updated ppa repo to the server
#rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/
