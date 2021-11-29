#!/bin/bash

if [ ! -d .git ]; then
    echo "Git not initialized"
    exit 1;
fi;

GIT_HOOK_FILE=".git/hooks/commit-msg"

curl https://raw.githubusercontent.com/harryjjacobs/enforce-git-message/master/enforce_git_message/git-templates/hooks/commit-msg -o $GIT_HOOK_FILE
chmod +x $GIT_HOOK_FILE

echo "Development environment configured successfully"