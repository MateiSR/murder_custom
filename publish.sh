#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tools_dir=$(CDPATH= cd -- "$repo_dir/../../.." && pwd)/bin

if [ "$#" -ne 1 ]; then
	printf 'Usage: %s <numeric-id>\n' "$0" >&2
	exit 2
fi
case $1 in
	''|*[!0-9]*) printf 'Workshop ID must be numeric.\n' >&2; exit 2 ;;
esac

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

gmpublish=$(find_tool gmpublish)
LD_LIBRARY_PATH=$(dirname -- "$gmpublish"):$tools_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
cd "$repo_dir"
"$gmpublish" update -addon packed.gma -id "$1"
