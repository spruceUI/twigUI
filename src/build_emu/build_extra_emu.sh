#!/bin/bash

jsonf=$(cat extra_emu.json)

if [ $1 = "all" ] ; then
  echo "all"

  while read jvalue
  do
    name=$(echo "$jvalue" | jq -r .name)
    repo=$(echo "$jvalue" | jq -r .repo)
    script=$(echo "$jvalue" | jq -r .script)

    if [ ! -d "$name" ]; then
      git clone --recursive $repo

      cd scripts/
      ./$script
    else
      echo "${name} directory exists, skipping."
    fi

  done < <(echo "$jsonf" | jq -c '.cores[]')
else
  if [ -f "scripts/${1}.sh" ] ; then
    jdata=$(echo $jsonf | jq '.cores[]  | select(.name == "'"$1"'")')

    name=$(echo "$jdata" | jq -r .name)
    repo=$(echo "$jdata" | jq -r .repo)
    script=$(echo "$jdata" | jq -r .script)

    git clone --recursive $repo

    cd scripts/
    ./$script
  else
    echo "Script not found."
  fi
fi
