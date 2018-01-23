#!/usr/bin/env bash

set -euxo pipefail

TOKEN=$(git config --global --includes --get github.token | tr -d '\n')
AUTH="token ${TOKEN}"

if [ "$@" ]
then
  if [[ $@ == */* ]]
  then
    coproc ( xdg-open https://github.com/$@ & > /dev/null 2>&1 )

  else
    # Url-encode query string
    q=$(printf "${@} in:name" | jq -R -r @uri)

    http GET https://api.github.com/search/repositories\?q=${q} "Authorization:${AUTH}" | jq -r '.items | map(.full_name) | .[]'
  fi
else
  http GET https://api.github.com/user/starred "Authorization:${AUTH}" | jq -r 'map(.full_name) | .[]'
fi
