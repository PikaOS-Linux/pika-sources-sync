#! /bin/bash
set -e

# Give correct perms to Apt version checker
chmod 755 ./ppp

ssh ferreo@direct.pika-os.com 'aptly repo remove pikauwu-rocm libva-dev'

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo add -force-replace -remove-files pikauwu-rocm /srv/www/incoming/'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
