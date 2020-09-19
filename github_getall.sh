#!/bin/bash -e

#Copyright 2020 KO4FZG.COM
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#

#Github-Download-Releases-Source
#https://github.com/KO4FZG/Github-Download-Releases-Source

#Version: 1.0
#Usage: github_getall.sh <repo_url>
#Example: ./github_getall.sh https://github.com/pa3gsb/Radioberry-2.x

HTML_OUT=$(mktemp)
ASSETS_LIST=$(mktemp)
WGET_OPT='-q --no-check-certificate'

if [ $# -ne 1 ]; then
  echo "Usage: $0 <repo_url>"; exit 1;
fi

if [ -d 'releases' ]; then
  echo "Error: releases/ exists!"; exit 1;
fi

REPO_URL=${1}
REPO_PATH="/$(echo $REPO_URL | cut -f4,5 -d/)"
RELEASES=''

#Download the release page
AFTER_URL='/releases'

while [ 1 -eq 1 ]; do

  echo "Parsing versions from ${AFTER_URL}"

  RELEASE_URL="${REPO_URL}${AFTER_URL}"
  wget ${WGET_OPT} -O${HTML_OUT} "${RELEASE_URL}"

  #Get all release versions
  PAGE_RELEASES=$(sed -n 's/.*\/\(tree\|tag\)\/\([^"]*\)".*/\2/p' $HTML_OUT | sort -Vr | uniq | xargs)

  if [ "${PAGE_RELEASES}" ]; then
    RELEASES="${RELEASES} ${PAGE_RELEASES}"
  fi

  #append asset names to list
  sed -n 's/.*\(\/\(archive\|releases\/download\)[^"]*\)".*/\1/p' $HTML_OUT >>${ASSETS_LIST}

  #check if we have a next link
  AFTER_VER=$(sed -n 's/.*\/releases?after=\([^"]*\)">Next.*/\1/p' ${HTML_OUT})
  if [ -z "${AFTER_VER}" ]; then
    break;
  fi
  AFTER_URL="/releases?after=${AFTER_VER}"
done

echo "Releases: ${RELEASES}"

mkdir -p releases
pushd releases
  for rel in ${RELEASES}; do
    mkdir -p ${rel}

    while read ASSET; do
      echo "${REPO_URL}${ASSET}"
      wget ${WGET_OPT} -P${rel} "${REPO_URL}${ASSET}"
    done <<< $(grep $rel ${ASSETS_LIST})
  done
popd

rm -f "${HTML_OUT}" "${ASSETS_LIST}"
