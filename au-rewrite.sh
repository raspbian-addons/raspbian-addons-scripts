#!/bin/bash

#########################################
#            au-rewrite.sh              #
# downloads and writes certain packages #
#           every 24 hours              #
#########################################

PKGDIR="/root/raspbian-addons/debian/pkgs_incoming/"
DATEA="$(date)"

# print the date to console (for logging purposes)
echo $DATEA

# ensure folder for downloads is available
mkdir -p ~/dlfiles
cd ~/dlfiles
rm -rf *

# create data directory, for storing the version.txt file
mkdir -p $HOME/dlfiles-data

# ensure armhf arch is added
sudo dpkg --add-architecture armhf

function error {
  echo -e "\e[91m$1\e[39m"
  exit 1
}

function redtext {
  echo -e "\e[91m$1\e[39m"
}

echo "Updating codium."
CODIUM_API=`curl -s https://api.github.com/repos/VSCodium/VSCodium/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
CODIUM_DATAFILE="$HOME/dlfiles-data/codium.txt"
if [ ! -f "$CODIUM_DATAFILE" ]; then
    echo "$CODIUM_DATAFILE does not exist."
    echo "Grabbing the latest release from GitHub."
    echo $CODIUM_API > $CODIUM_DATAFILE
fi
CODIUM_CURRENT="$(cat $CODIUM_DATAFILE)"
if [ "$CODIUM_CURRENT" != "$CODIUM_API" ]; then
    curl -s https://api.github.com/repos/VSCodium/VSCodium/releases/latest \
      | grep browser_download_url \
      | grep 'armhf.deb"' \
      | cut -d '"' -f 4 \
      | xargs -n 1 curl -L -o codium_${LATEST}_armhf.deb || error "Failed to download the codium:armhf"

    curl -s https://api.github.com/repos/VSCodium/VSCodium/releases/latest \
      | grep browser_download_url \
      | grep 'arm64.deb"' \
      | cut -d '"' -f 4 \
      | xargs -n 1 curl -L -o codium_${LATEST}_arm64.deb || error "Failed to download codium:arm64"

    mv codium* $PKGDIR
    echo "vscodium downloaded successfully."
fi



echo "Writing packages."
cd /root/raspbian-addons/debian
for new_pkg in `ls pkgs_incoming`; do
    echo $new_pkg
    #reprepro_expect
    /root/reprepro.exp -- --noguessgpgtty -Vb /root/raspbian-addons/debian/ includedeb precise /root/raspbian-addons/debian/pkgs_incoming/$new_pkg
    if [ $? != 0 ]; then
        redtext "Import of $new_pkg failed!"
    else
        rm -rf pkgs_incoming/$new_pkg
    fi
done