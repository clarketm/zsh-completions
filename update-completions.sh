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
# copy various completion files => src/
################################################
cp -Lrf \
    "/usr/local/share/zsh/site-functions/_"* \
 	"/usr/local/share/zsh/site-functions/"*".bash" \
    "$cwd/src/"

command -v poetry >/dev/null && poetry completions zsh > "$cwd/src/_poetry"
command -v kind >/dev/null && kind completion zsh > "$cwd/src/_kind"
command -v glooctl >/dev/null && glooctl completion zsh > "$cwd/src/_glooctl"
command -v gh >/dev/null && gh completion -s zsh > "$cwd/src/_gh"

cp -Lrf \
	"$HOME/google-cloud-sdk/completion.zsh.inc" \
	"$cwd/src/_gcloud" \
	&& sed -i '1i #compdef gcloud' "$cwd/src/_gcloud"

################################################
# copy override/ => src/
################################################
cp -Lrf \
    "$cwd/override/_"* \
    "$cwd/src/"

################################################
# handle options
################################################
if [ "$1" != "--dry-run" ]; then
	git pull && git add . && git commit -m "$(date -Iseconds)" && git push origin master || echo "nothing to commit :)"
fi
