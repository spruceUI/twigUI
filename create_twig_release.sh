#!/bin/bash

MAINLINE_COMMIT="77d397fc0d1219d6f801ab560aa8447e5b444874"
CURRENT_COMMIT=$(cat current_commit.txt)

TMP_DIR="tmp/"
REL_DIR="release/"
OUT_FILE=twigUI_"$(date +'%d.%m.%Y')"

rm twig*.7z
rm twig*.img
rm twig*.img.gz

# Clone main repo with specific commit
cd $TMP_DIR

if [ "$CURRENT_COMMIT" != "$MAINLINE_COMMIT" ]; then
  rm -rf *

  git clone --revision=$MAINLINE_COMMIT --depth=1 https://github.com/spruceUI/spruceOS.git
  git clone --depth=1 https://github.com/spruceUI/pixel2-base.git
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
for f in $(cat delete.txt) ; do
  rm -r "$f"
done

# Make archive and clean up
7z a -t7z -mx=9 -mf- "${OUT_FILE}_update.7z" ./"${TMP_DIR}${REL_DIR}"*
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

