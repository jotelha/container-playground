#!/bin/bash
set -euo pipefail

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL="INFO"
DRY_RUN=

DELIM='_'
PREFIX=
SUFFIX='.sif'

_log() {
    local log_priority=$1
    local log_message=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    if (( ${levels[$log_priority]} >= ${levels[$LOG_LEVEL]} )); then
        echo "${log_priority} : ${log_message}"
    fi
}

usage() {
  echo -n "
Usage: $(basename "$0") [-dhnv] [--delimiter DELIM] [--prefix PREFIX] [--suffix SUFFIX] FILES

Strip file names of FILES off PREFIX (default: '${PREFIX}') and SUFFIX (default: '${SUFFIX}'),
split remainder in components delimited by DELIM (default:'$DELIM'),
sort components alphabetically and rename original files accordingly.

"
}

function join_by { local IFS="$1"; shift; echo "$*"; }

args=$(getopt -n "$0" -l "help,verbose,debug,dry-run,delimiter:,prefix:,suffix:" -o "hvdn" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    --delimiter) DELIM=$2; shift; shift;;
    --prefix) PREFIX=$2; shift; shift;;
    --suffix) SUFFIX=$2; shift; shift;;
    -h | --help ) usage ; exit 0 ;;
    -n | --dry-run ) DRY_RUN=true; shift;;
    -v | --verbose ) LOG_LEVEL="INFO"; shift ;;
    -d | --debug ) LOG_LEVEL="DEBUG"; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# positional arguments
FILES=$@

_log DEBUG "delimiter: ${DELIM}"
_log DEBUG "prefix: ${PREFIX}"
_log DEBUG "suffix: ${SUFFIX}"

for file in ${FILES[@]}; do
    _log DEBUG "file: ${file}"
    prefixed_name=${file%"$SUFFIX"}
    name=${prefixed_name#"$PREFIX"}
    _log DEBUG "name: ${name}"
    IFS=${DELIM} read -r -a components <<< "${name}"
    _log DEBUG "#components: ${#components[@]}"
    _log DEBUG "components: ${components[*]}"
    IFS=$'\n' sorted_components=($(sort <<<"${components[*]}")); unset IFS
    _log DEBUG "sorted components: ${sorted_components[*]}"
    new_name=$(join_by ${DELIM} ${sorted_components[*]})
    _log DEBUG "new name: ${new_name}"
    new_file="${PREFIX}${new_name}${SUFFIX}"
    _log DEBUG "new file: ${new_file}"
    if [ "${file}" == "${new_file}" ]; then
        _log WARN "File '${file}' already named properly. Nothing to be done."
    else
        cmd="mv ${file} ${new_file}"
        _log INFO "exec: ${cmd}"
        if [ -z "${DRY_RUN}" ]; then $cmd; fi
    fi
done
