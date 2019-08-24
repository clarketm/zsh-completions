#!/usr/bin/env sh

cwd=$(cd "$(dirname "$0")" && pwd)

git submodule sync --recursive
git submodule update --recursive --remote

cp -Lrf \
    "$cwd/nilsonholger_zsh-completions/_"* \
    "$cwd/src/"

cp -Lrf \
    "$cwd/zchee_zsh-completions/src/zsh/_"* \
    "$cwd/zchee_zsh-completions/src/macOS/_"* \
    "$cwd/src/"

cp -Lrf \
    "$cwd/zsh-users_zsh-completions/src/_"* \
    "$cwd/src/"

cp -Lrf \
    "$cwd/custom/_"* \
    "$cwd/src/"

if [ "$1" != "--dry-run" ]; then
	git commit -am "$(date +%F)" && git push --tags origin master
fi
