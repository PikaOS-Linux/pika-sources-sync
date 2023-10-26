#! /bin/bash
set -e

# publish all the repos
ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite lunar filesystem:pikarepo:'

ssh ferreo@direct.pika-os.com 'aptly publish update -batch -skip-contents -force-overwrite pikauwu filesystem:pikarepo:'
