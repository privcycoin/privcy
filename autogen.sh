#!/bin/bash -e

[ -d .git ] && [ -d tor ] || \
  { echo "Please run this command from the root of a recursive clone of the PRiVCY Coin Github.com repository." && exit 1; }

git submodule init 
git submodule sync --recursive 
git submodule update --recursive --force

autoreconf --no-recursive --install

PATCH="patch --no-backup-if-mismatch -f"

pushd tor
./autogen.sh
popd
