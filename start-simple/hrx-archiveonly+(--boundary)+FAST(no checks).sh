#!/bin/sh

case $1 in --help)
	printf %s\\n \
		"Usage: ${0##*/} [-c|-x] [-f OUTFILE] [--boundary <====>] [--] [FILES...]" \
		"" \
		"  Caughtion: no checks no validations of input" \
		"   boundary should be the exactly boundary to print, no processing by this script" \
		"" \
		"  Archives files and directories recursively." \
	;
	exit
esac

die() {
	printf %s\\n "$@" >&2
	exit ${2-2}
}

unset opt_c
unset opt_x
unset opt_f_val
unset opt_boundary_val
while case $# in 0) false; esac; do
	case $1 in
		-c) opt_c='';;
		-x) opt_x=''; die "E: extraction is not currently supported" 4;;
		-f) opt_f_val=${2?}; shift;;
		--boundary) opt_boundary_val=${2?}; shift;;
		--) shift; break;;
		-*) die "E: Unknown option: '$1'";;
		*) break;;
	esac
shift; done


case ${opt_boundary_val+x} in
	x) boundary=$opt_boundary_val
	*) boundary='<===>' # default
esac

case ${opt_f_val--} in -) ;; *)
	exec > "$opt_f_val"
esac



## TODO:!!!!! 
## TODO:!!!!! 
## TODO:!!!!! after here remove all cehcks, besides the dirs, and trust thet arguments for if its dir
## TODO:!!!!! 
## TODO:!!!!! 



# TODO: we must also check for read permissions

archive_file_direct() {
	printf ${s+\\n}%s\\n "$boundary $1"
	cat -- "$1" # TODO:! here we could get read error
	s=
}

archive_empty_dir_direct() {
	printf ${s+\\n}%s\\n "$boundary ${1%/}"
	unset s
}


archive_file_check() {
	if [ -e "$1" ]; then
		: # all ok
	elif [ -L "$1" ]; then
		printf %s\\n >&2 "W: (1) non existing symlink: '$1'"
		return 1
	else
		printf %s\\n >&2 "W: (2) non existing path: '$1'"
		return 1
	fi
	# note: we don't check if its of type file,
	# this does not practically matter

	archive_file_direct "$1"
}


archive_dir_recursive() {
	# one arg only!
	# and $1 is pre-checked to be dir

	set -- "$1"/* # TODO:! this wont cause error (wont even stderr) if we dont have permissions
	case $# in 1) case $1 in *'/*') # who does this
		if [ -e "$1" ]; then # single file in single folder, but why is it named `*'/*'`
			archive_file "$1"
			return
		elif [ -L "$1" ]; then # what is the chance of ever getting `*'/*'` on accident
			printf %s\\n >&2 "W: (3) non existing symlink: '$1'"
			archive_empty_dir_direct "${1%'*'}"
			# return 1 # idk, for now no return errs
			return
		else
			archive_empty_dir_direct "${1%'*'}"
			return # no err, just empty dir
		fi
	esac; esac

	archive "$@"
}

archive_dir_recursive_check() {
	# TODO:!HERE check if have read permissions? or upper archive fn?

	[ -d "$1" ] || return 1


	archive_dir_recursive "$1"
}




archive() {
	for f; do
		# TODO:!HERE check if have read permissions

		case $f in */) ;; *)
			archive_dir_recursive_check "${f%/}" || {
				err_collect=$(( err_collect + 1 ))
				printf %s\\n "W: (4) path '${f}' is not directory or does not exist"
			}
			continue
		esac

		if [ -d "$f" ]; then
			# for now do not prepend dir starting (if not empty dir)
			#archive_empty_dir_direct "$f"
			archive_dir_recursive "$f"
		else
			archive_file "$f"
		fi
	done
}




err_collect=0
unset s # keep track if we are on first line, reason: EOFNL for last file should not be duplicated
archive "$@"
