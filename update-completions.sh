#!/usr/bin/env sh

cwd=$( cd "$( dirname "$0" )" && pwd )

git submodule update --recursive --remote

cp -Lrf \
"$cwd/zchee_zsh-completions/src/zsh/_"* \
"$cwd/"

cp -Lrf \
"$cwd/zsh-users_zsh-completions/src/_"* \
"$cwd/"

