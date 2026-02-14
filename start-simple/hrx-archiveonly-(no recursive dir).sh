#!/bin/sh

case $1 in --help)
	printf %s\\n \
		"Usage: ${0##*/} [-f OUTFILE] [--] [FILES...]" \
		"" \
		"  NOTE:! for files in directories" \
		"  requires each file to be passed as separate argument" \
	;
	exit
esac

unset opt_f_val

case $1 in '-f')
	case $# in 1)
		printf %s\\n >&2 "E: -f requires an argument"
		exit 2
	esac
	opt_f_val=$2; shift 2
esac

case $1 in '--')
	shift
esac

case ${opt_f_val--} in -) ;; *)
	exec > "$opt_f_val"
esac

unset s # keep track if we are on first line, reason: EOFNL for last file should not be duplicated
for f; do
	if case $f in */) ;; *) [ -d "$f" ];; esac; then
		printf %s\\n '<===> ${f%/}/'
		unset s
	else
		printf ${s+\\n}%s\\n "<===> $f"
		cat -- "$f"
		s=
	fi
done
