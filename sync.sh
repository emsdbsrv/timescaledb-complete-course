#!/bin/sh

echo "Syncing to GitHub..."

git add .

read -p "Commit message: " msg

if [ -z "$msg" ]; then
  msg="Update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

git commit -m "$msg"
git push -u origin main

echo "Done!"
