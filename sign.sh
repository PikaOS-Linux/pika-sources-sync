#! /bin/bash
set -e

dpkg-sig $@ &
wait $last_pid