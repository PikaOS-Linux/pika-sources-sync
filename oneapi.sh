#! /bin/bash
set -e

# add debs to repo
ssh ferreo@direct.pika-os.com 'aptly repo create -distribution=pikauwu -component=oneapi pikauwu-oneapi'

# publish the repo
ssh ferreo@direct.pika-os.com 'aptly publish repo -component=,  pikauwu-oneapi filesystem:pikarepo:'
