#!/bin/sh

EMPTY_DIR="# Ignore contents of this directory\n*\n# Except this file\n!.gitignore\n"
IMPORTED_REPOS="github.com\n"
GO_SETUP="export GOPATH=$(pwd)/\n"

mkdir bin
printf "$EMPTY_DIR" > bin/.gitignore

mkdir pkg
printf "$EMPTY_DIR" > pkg/.gitignore

mkdir src
printf "$IMPORTED_REPOS" > src/.gitignore

printf "$GO_SETUP" > setup
