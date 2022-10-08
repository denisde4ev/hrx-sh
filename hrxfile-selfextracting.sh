#!/bin/sh

case $1 in
--help)
	printf %s\\n "Usage: ${##*/} [-x] [EXTRACT FILES]..."
	exit
	;;
-x)
	set -x
	shift
	;;
-*)
	printf %s\\n >&2 "use --help for usage"
	exit 2
	;;
esac

boundary='<==>'

sed -ne '/^@@ HRX @@$/,$ p' -- "$0" | {
	read -r _ # ignore line "@@ HRX @@"

	ftype=error
	read -r line || case $line in '') break; esac
	while :; do
		case $line in
		"$boundary "[!\ ]*/)
			dirname=${line#"$boundary "}
			mkdir -pv -- ./"$dirname"
			read -r line
			;;
		"$boundary "[!\ ]*)
			fname=${line#"$boundary "}
			printf %s\\n "file: $fname"
			case $fname in */*) mkdir -pv -- "${fname%/*}"; esac
			: >"$fname"
			while read -r line; do case $line in "$boundary"*) continue 2; esac
				printf %s\\n "$line" >>./"$fname"
			done
			;;
		"$boundary"|"$boundary  "*)
			while read -r line; do case $line in "$boundary"*) continue 2; esac
				printf %s\\n "comment: $line"
			done
			;;
		*)
			printf %s\\n >&2 "expected to find boundary in line: '$line'"
			read -r line
		esac

		case $line in '') break; esac
	done
}

exit

@@ HRX @@
<==> file-1
this is the content of file 1
<==>
this is a comment
<==>
<==> file-2
this is the content of file 2
<==> file-3
thi is tha file 3
<==>
<==> dir2/
<==>
<==> empty-file
<==>
<==> dir/
<==>
<==> dir/a
file a
<==> dir3/b
file b
