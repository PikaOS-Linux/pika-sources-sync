#! /bin/bash
set -e

### In the Case of a major mishap we wipe the external pool clean and re run all repos
# Pull down existing ppa repo db files etc
mkdir -p ./output/repo
rsync -azP --exclude '*.deb' ferreo@direct.pika-os.com:/srv/www/pikappa/ ./output/repo

# Remove our All package from the pool
reprepro -C external -V --basedir ./output/repo/ removefilter lunar 'Package (% *)'

# Push the updated ppa repo to the server
rsync -azP ./output/repo/ ferreo@direct.pika-os.com:/srv/www/pikappa/