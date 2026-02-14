#!/bin/sh

case $1 in --help)
	printf %s\\n \
		"Usage: ${0##*/} [-f OUTFILE] [--] [FILES...]" \
		"" \
		"  Archives files and directories recursively." \
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




# TODO: we must also check for read permissions


archive_file() {
	printf ${s+\\n}%s\\n "<===> $1"
	cat -- "$1"
	s=
}

archive_empty_dir() {
	printf '<===> %s/\n' "${1%/}"
	unset s
}


archive_dir_recursive() { # one arg only!
	set -- "$1"/*
	case $# in 1) case $1 in *'/*') # who does this
		if [ -e "$1" ] || [ -L "$1" ]; then
			archive_file "$1"
			return
		else
			archive_empty_dir "${1%'*'}"
			return # no err, just empty dir
		fi
	esac; esac

	archive "$@"
}

archive() {
	for f; do
		if case $f in */) ;; *) [ -d "$f" ];; esac; then
			# for now do not prepend dir starting (if not empty dir)
			#archive_empty_dir "$f"
			archive_dir_recursive "$f"
		else
			archive_file "$f"
		fi
	done
}

unset s # keep track if we are on first line, reason: EOFNL for last file should not be duplicated
archive "$@"
