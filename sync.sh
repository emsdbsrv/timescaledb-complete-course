#!/bin/bash

git config core.safecrlf false
git config core.autocrlf true

echo "Syncing to GitHub..."

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "master" ]; then
    git branch -M main
    BRANCH="main"
fi

git add .

read -p "Commit message: " msg

if [ -z "$msg" ]; then
    msg="Update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

git commit -m "$msg"
git push -u origin $BRANCH

echo "Done!"
