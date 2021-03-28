#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused nix-prefetch jq

set -e

dirname="$(dirname "$0")"

updateHash()
{
    version=$1
    suffix=$2

    hashKey="${suffix}_hash"

    url="https://github.com/Jackett/Jackett/releases/download/v$version/Jackett.Binaries.$suffix.tar.gz"
    hash=$(nix-prefetch-url --type sha256 $url)
    sriHash="$(nix to-sri --type sha256 $hash)"

    sed -i "s|$hashKey = \"[a-zA-Z0-9\/+-=]*\";|$hashKey = \"$sriHash\";|g" "$dirname/default.nix"
}

updateVersion()
{
    sed -i "s/version = \"[0-9.]*\";/version = \"$1\";/g" "$dirname/default.nix"
}

currentVersion=$(cd $dirname && nix eval --raw '(with import ../../.. {}; jackett.version)')

latestTag=$(curl https://api.github.com/repos/Jackett/Jackett/releases/latest | jq -r ".tag_name")
latestVersion="$(expr $latestTag : 'v\(.*\)')"

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "Jackett is up-to-date: ${currentVersion}"
    exit 0
fi

echo $currentVersion $latestVersion;

updateVersion $latestVersion

updateHash $latestVersion LinuxAMDx64
updateHash $latestVersion LinuxARM64
updateHash $latestVersion macOS
