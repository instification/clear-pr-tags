#!/bin/bash

# ENV VARS USED:
# GITHUB_TOKEN - used to authenticate with git
# GITHUB_EVENT_PATH - contains the pull request we need to act against

REPO=$(jq --raw-output .repo.full_name "GITHUB_EVENT_PATH")
PR=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
echo "We are working on ${REPO}/pulls/${PR}" >> $GITHUB_OUTPUT

# Get commits on this PR
shas=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/pulls/${PR}/commits | jq '.[].sha'| tr -d '"')

# Get tags
tags=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/tags | jq '.[] | "\(.commit.sha) \(.name)"'|tr -d '"')

echo "Tags: $tags" >> $GITHUB_OUTPUT

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

echo "Finished processing tags. ${#tagsToDelete[@]} to delete." >> $GITHUB_OUTPUT 

# Delete the tags
for tag in "${tagsToDelete[@]}"
do
    echo "Deleting $tag" >> $GITHUB_OUTPUT
    curl -L \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/pretagov/${REPO}/git/refs/tags/${tag} 2>&1 >> $GITHUB_OUTPUT
done
