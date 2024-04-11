#!/usr/bin/env bash
#
# Based on: https://gist.github.com/foca/3148204
#
# Install into:
# - .git/hooks/post-checkout
# - .git/hooks/post-merge
# - .git/hooks/post-rewrite
# - .git/hooks/post-commit
#
# And make sure all are executable.
#
# Then change the $MANIFEST_FILE_PATH appropriately.
# The path starts from the root of the repository.

MANIFEST_FILE_PATH="west.yml"

if ! git diff --exit-code --quiet HEAD@{1}..HEAD@{0} "$MANIFEST_FILE_PATH"; then
	west update
fi
