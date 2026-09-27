#!/usr/bin/env bash

# Dusklight downloader (Linux x86_64)
#
# Downloads the latest Dusklight AppImage from GitHub. The linux-x86_64
# build is the one we want; the -x86_64 suffix is also what excludes the
# linux-arm64 build.
#
# Everything sits next to this script, with no folders:
#
#     dusklight-downloader.sh
#     dusklight.appimage        the AppImage itself
#     dusklight-version.txt     the version currently installed
#
# The version file is what says what is installed, so the AppImage can keep a
# fixed name and be overwritten in place on upgrade instead of piling up.
#
# Files are placed next to this script, so it can be run from anywhere.
# It takes no arguments.
#
# Requires bash, curl and python3.

set -euo pipefail

# Asset suffix to look for
suffix="-linux-x86_64.AppImage"

# What the AppImage is called, and the file recording its version
appimage_name="dusklight.appimage"
version_file="dusklight-version.txt"

# Work out the directory holding this script, following any symlinks, so the
# install lands beside the downloader rather than in the caller's cwd.
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
    link_dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    case "$src" in
        /*) ;;
        *) src="$link_dir/$src" ;;
    esac
done
script_dir="$(cd -P "$(dirname "$src")" && pwd)"

# Install next to this script
cd -- "$script_dir"

# Define the URL for the latest release
url="https://api.github.com/repos/TwilitRealm/dusklight/releases/latest"

# Find the name and browser_download_url of the linux x86_64 AppImage asset
asset="$(
    curl -fsSL "$url" | python3 -c '
import json, sys

suffix = sys.argv[1]
for a in json.load(sys.stdin).get("assets", []):
    if a["name"].endswith(suffix):
        print(a["name"], a["browser_download_url"])
        break
else:
    sys.exit("error: no asset ending in %s in the latest release" % suffix)
' "$suffix"
)"

read -r asset_name download_url <<<"$asset"

# Extract the version number from the asset name,
# e.g. Dusklight-v2.0.2-linux-x86_64.AppImage -> 2.0.2
latest_version="${asset_name#Dusklight-v}"
latest_version="${latest_version%$suffix}"

# Read the installed version, if it was recorded. Anything unrecognised is
# treated as no record at all, so a damaged file just triggers a fresh install.
installed_version=""
if [ -f "$version_file" ]; then
    installed_version="$(tr -d '[:space:]' <"$version_file")"
    case "$installed_version" in
        "" | .* | *. | *[!0-9.]*) installed_version="" ;;
    esac
fi

# Work out whether to download. sort -V is used for the comparison so that
# 2.0.10 correctly beats 2.0.9.
if [ -z "$installed_version" ]; then

    echo "No Dusklight found. Installing $latest_version..."

elif [ ! -f "$appimage_name" ]; then

    # The version file survived but the AppImage did not, so reinstall.
    echo "Installed Dusklight $installed_version is missing $appimage_name. Reinstalling $latest_version..."

elif [ "$latest_version" = "$installed_version" ]; then

    echo "Dusklight $installed_version is already up to date."
    exit 0

elif [ "$(printf '%s\n%s\n' "$latest_version" "$installed_version" | sort -V | head -1)" = "$installed_version" ]; then

    echo "Updating Dusklight $installed_version -> $latest_version"

else

    # Only reachable if the latest release is older than what is installed,
    # e.g. a release was withdrawn. Never downgrade over a newer build.
    echo "Installed Dusklight $installed_version is newer than the latest release ($latest_version). Leaving it alone."
    exit 0

fi

# Download to a temporary name and only replace the real one once the file is
# complete, so an interrupted download can never destroy a working install.
if ! curl -# -fL -o "$appimage_name.part" "$download_url"; then
    rm -f -- "$appimage_name.part"
    echo "error: download failed" >&2
    exit 1
fi
mv -f -- "$appimage_name.part" "$appimage_name"

# An AppImage is only runnable once the executable bit is set
chmod +x "$appimage_name"

# Record the version last, so a failed download leaves the previous version
# recorded and the next run retries rather than thinking it is up to date.
printf '%s\n' "$latest_version" >"$version_file.part"
mv -f -- "$version_file.part" "$version_file"

echo "Dusklight $latest_version installed to $appimage_name"
