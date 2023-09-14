#!/bin/bash

# ENV VARS USED:
# INPUT_GITHUB_TOKEN - used to authenticate with git
# GITHUB_EVENT_PATH - contains the pull request we need to act against

#REPO=$(jq --raw-output .repo.full_name "$GITHUB_EVENT_PATH")
REPO=${GITHUB_REPOSITORY}
PR=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")


[[ -n ${INPUT_GITHUB_TOKEN} ]] || { echo "Please set the GITHUB_TOKEN input"; exit 1; }

shas=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/pulls/${PR}/commits 2>/dev/null| jq '.[].sha'| tr -d '"')

echo "SHAS: $shas"

# Get tags
tags=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/tags  2>/dev/null| jq '.[] | "\(.commit.sha) \(.name)"'|tr -d '"')

echo "TAGS: $tags"


# Work out which tags to delete
tagsToDelete=()
while IFS= read -r line; do
    name=`echo ${line} | awk {'print $2'}`
    sha=`echo ${line} | awk {'print $1'}`
    for insha in $shas
    do
        if [ "$sha" == "$insha" ]
        then
            tagsToDelete+=($name)
            break
        fi
    done
done <<< "$tags"

# Delete the tags
for tag in "${tagsToDelete[@]}"
do
    echo "Deleting tag: $tag"
    curl -L \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/pretagov/${REPO}/git/refs/tags/${tag}
done
