echo "Done!"
#!/bin/bash

git config core.safecrlf false
git config core.autocrlf true

echo "Syncing to GitHub..."

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$BRANCH" = "master" ]; then
    git branch -M main
    BRANCH="main"
fi

echo "Current branch: $BRANCH"
echo ""

git add .

echo "Enter commit message:"
read -p "> " msg

if [ -z "$msg" ]; then
    msg="Update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo ""
echo "Staging files..."
git add .

echo "Committing with message: $msg"
git commit -m "$msg"

echo "Pushing to origin/$BRANCH..."
git push -u origin $BRANCH

echo ""
echo "=========================================="
echo "✓ Sync complete!"
echo "Branch: $BRANCH"
echo "Message: $msg"
echo "=========================================="
