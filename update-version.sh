#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "usage: $0 version message"
	exit 1
fi

version_to_number() {
	major=`echo "$1" | cut -d . -f 1`
	minor=`echo "$1" | cut -d . -f 2`
	patch=`echo "$1" | cut -d . -f 3`

	expr "$major" "*" 1000 + "$minor" "*" 100 + "$patch"
}

version="$1"
message="$2"

version_num=`version_to_number "$version"`
current_version=`grep ^Version syncer/SPECS/atomiadns-nameserver.spec | cut -d " " -f 2`
current_version_num=`version_to_number "$current_version"`

if [ -z "$version_num" ] || [ -z "$current_version_num" ]; then
	echo "error: calculating version number for $version or $current_version"
	exit 1
fi

if [ ! "$version_num" -gt "$current_version_num" ]; then
	echo "error: current version $current_version is not lower than $version"
	exit 1
fi

find dyndns syncer server -name "*.spec" -type f | while read f; do
	version_subs="%%s/^Version: .*/Version: $version/"
	require_subs="%%s/^Requires: atomiadns-api >= .* atomiadns-database >= .*/Requires: atomiadns-api >= $version atomiadns-database >= $version/"
	goto_changelog="/^%%changelog/+1i"
	change_header="* $(date +"%a %b %d %Y") Jimmy Bergman <jimmy@atomia.com> - ${version}-1"
	ed_script=`printf "$version_subs\n$require_subs\n$goto_changelog\n$change_header\n- $message\n.\nw\nq\n"`
	echo "$ed_script" | ed "$f"
done