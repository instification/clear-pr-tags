#!/bin/sh

# ENV VARS USED:
# GITHUB_TOKEN - used to authenticate with git
# GITHUB_ACTION_REPOSITORY - the repo being acted upon
# GITHUB_EVENT_PATH - contains the pull request we need to act against

PR=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

# Get commits on this PR
shas=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GITHUB_ACTION_REPOSITORY}/pulls/${PR}/commits 2> /dev/null| jq '.[].sha'| tr -d '"')

# Get tags
tags=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GITHUB_ACTION_REPOSITORY}/tags 2> /dev/null | jq '.[] | "\(.commit.sha) \(.name)"'|tr -d '"')


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
    curl -L \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/pretagov/${GITHUB_ACTION_REPOSITORY}/git/refs/tags/${tag} 2> /dev/null
done
