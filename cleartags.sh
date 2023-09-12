#!/bin/bash

# ENV VARS USED:
# INPUT_GITHUB_TOKEN - used to authenticate with git
# GITHUB_EVENT_PATH - contains the pull request we need to act against

#REPO=$(jq --raw-output .repo.full_name "$GITHUB_EVENT_PATH")
REPO=${GITHUB_REPOSITORY}
PR=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
echo "repo=${REPO}/pulls/${PR}" >> $GITHUB_OUTPUT

# Get commits on this PR
shas_raw=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/pulls/${PR}/commits)

echo "RAW Shas: $shas_raw"

echo "sha=${shas_raw}" >> $GITHUB_OUTPUT

shas=`echo ${shas_raw} | jq '.[].sha'| tr -d '"'`

# Get tags
tags_raw=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/tags)
  

echo "tags=${tags_raw}" >> $GITHUB_OUTPUT
tags=`echo ${tags_raw} | jq '.[] | "\(.commit.sha) \(.name)"'|tr -d '"'


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

tdd=`printf -v joined '%s,' "${tagsToDelete[@]}"`
echo "deleting=$tdd" >> $GITHUB_OUTPUT 

# Delete the tags
for tag in "${tagsToDelete[@]}"
do
    echo "Deleting $tag" >> $GITHUB_OUTPUT
    curl -L \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/pretagov/${REPO}/git/refs/tags/${tag}
done
