#!/bin/bash

MAINLINE_COMMIT="4eeb0b59cc9f4ad28ec94035efaf3ddb44f35da4"
CURRENT_COMMIT=$(cat current_commit.txt)

TMP_DIR="tmp/"
REL_DIR="release/"
OUT_FILE=twigUI_V"$(cat SDCARD/spruce/twig)"

rm twig*.7z
rm twig*.img
rm twig*.img.gz

# Clone main repo with specific commit
cd "$TMP_DIR"

if [ "$CURRENT_COMMIT" != "$MAINLINE_COMMIT" ]; then
  rm -rf *

  git clone --revision=$MAINLINE_COMMIT --depth=1 https://github.com/spruceUI/spruceOS.git
  git clone --depth=1 https://github.com/spruceUI/pixel2-base.git

  wget -nc -P spruceOS/Themes/ -i ../themes.txt

  echo $MAINLINE_COMMIT > ../current_commit.txt
fi

mkdir $REL_DIR

# Setup folders
GLOBIGNORE=/+/
rm -rf spruceOS/.git*
cp -r spruceOS/* $REL_DIR

rm $REL_DIR*.sh
rm $REL_DIR*.bat

# Copy new files
cd ..
cp -rf SDCARD/* "${TMP_DIR}${REL_DIR}"

# Delete uneeded files
shopt -s extglob
for f in $(cat delete.txt) ; do
  rm -r "$f"
done

# change some config defaults
jaq -i '.menuOptions."System Settings".useZRAM.selected = "True"' "${TMP_DIR}${REL_DIR}Saves/spruce/spruce-config.json"
jaq -i '.menuOptions."Battery Settings".idlemonChargingInMenu.selected = "30s"' "${TMP_DIR}${REL_DIR}Saves/spruce/spruce-config.json"

# Remove dev flag for releases
if [ "$1" = "release" ]; then
  rm "${TMP_DIR}${REL_DIR}spruce/flags/developer_mode"
fi

# Extract scummvm
SCVM_PATH="${TMP_DIR}${REL_DIR}RetroArch/.retroarch/cores64/"
unzip -d $SCVM_PATH "${SCVM_PATH}scummvm_libretro.zip"
rm "${SCVM_PATH}scummvm_libretro.zip"

# Make archive and clean up
7z a -t7z -mx=7 -mf- "${OUT_FILE}_update.7z" ./"${TMP_DIR}${REL_DIR}"*
rm -rf ${TMP_DIR}${REL_DIR}

wget -nc -O "${TMP_DIR}EMUELEC.7z" https://github.com/spruceUI/pixel2-base/releases/download/latest/EMUELEC.7z

# Setup files
7z x -aoa -o"${TMP_DIR}pixel2-base" "${TMP_DIR}EMUELEC.7z"
mkdir -p "${TMP_DIR}pixel2-base/storage/"
cp twig*.7z "${TMP_DIR}pixel2-base/storage/"

# Generate image and cleanup
genimage --inputpath tmp/pixel2-base/ --tmppath tmp/pixel2-base/tmp
mv images/IMAGE.img "${OUT_FILE}_install.img"
pigz --best --force "${OUT_FILE}_install.img"
rm -r images/
rm -r "${TMP_DIR}pixel2-base/storage/"

