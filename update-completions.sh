#!/usr/bin/env sh

cwd=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$cwd/src/"

git submodule sync --recursive
git submodule update --recursive --remote


################################################
# copy nilsonholger/zsh-completions/ => src/
################################################
cp -Lrf \
    "$cwd/nilsonholger_zsh-completions/_"* \
    "$cwd/src/"

################################################
# copy zchee/zsh-completions/ => src/
################################################
cp -Lrf \
    "$cwd/zchee_zsh-completions/src/zsh/_"* \
    "$cwd/zchee_zsh-completions/src/macOS/_"* \
    "$cwd/src/"

################################################
# copy zsh-users/zsh-completions/ => src/
################################################
cp -Lrf \
    "$cwd/zsh-users_zsh-completions/src/_"* \
    "$cwd/src/"

################################################
# copy various completion files => custom/
################################################

poetry completions zsh > "$cwd/custom/_poetry"
kind completion zsh > "$cwd/custom/_kind"
gh completion -s zsh > "$cwd/custom/_gh"

cp -Lrf \
	"$HOME/google-cloud-sdk/completion.zsh.inc" \
	"$cwd/custom/_gcloud"

cp -Lrf \
    "/usr/local/share/zsh/site-functions/_"* \
 	"/usr/local/share/zsh/site-functions/"*".bash" \
    "$cwd/custom/"

################################################
# copy custom/ => src/
################################################
cp -Lrf \
    "$cwd/custom/_"* "$cwd/custom/"*".bash" \
    "$cwd/src/"


if [ "$1" != "--dry-run" ]; then
	git pull && git add . && git commit -m "$(date +%F)" && git push origin master || echo "nothing to commit :)"
fi
