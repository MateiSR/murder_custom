#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tools_dir=$(CDPATH= cd -- "$repo_dir/../../.." && pwd)/bin

find_tool() {
	for tool in \
		"$tools_dir/linux64/$1" \
		"$tools_dir/linux64/${1}_linux" \
		"$tools_dir/linux32/$1" \
		"$tools_dir/linux32/${1}_linux" \
		"$tools_dir/${1}_linux"
	do
		[ ! -x "$tool" ] || { printf '%s\n' "$tool"; return; }
	done
	printf 'Could not find an executable %s under %s.\n' "$1" "$tools_dir" >&2
	return 1
}

gmad=$(find_tool gmad)
cd "$repo_dir"
rm -rf pack
mkdir pack
find . -mindepth 1 \
	\( -type d \( -name pack -o -name '.*' \) -prune \) -o \
	\( -type f ! -name '.*' ! -iname '*.md' ! -iname '*.ps1' ! -iname '*.sh' ! -iname '*.gma' ! -iname '*license.txt' -exec cp --parents '{}' pack/ ';' \)

LD_LIBRARY_PATH=$(dirname -- "$gmad"):$tools_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
"$gmad" create -folder pack -out packed.gma
