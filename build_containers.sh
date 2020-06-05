#!/bin/bash
set -euo pipefail

bootstrap_image="shahzebmsiddiqui/default/easybuild:centos-7"

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL="WARN"

log_msg() {
    local log_priority=$1
    local log_message=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$LOG_LEVEL]} )) && return 2

    #log here
    echo "${log_priority} : ${log_message}"
}

usage() {
  echo -n "
Usage: $(basename "$0") [-dhnv] [--image BOOTSTRAP_IMAGE] [EASY_CONFIG [EASY_CONFIG [ ... ]]]

Build stacked container images in current working directory from BOOTSTRAP_IMAGE (default: ${bootstrap_image}).

"
}

function join_by { local IFS="$1"; shift; echo "$*"; }

args=$(getopt -n "$0" -l "help,verbose,debug,dry-run" -o "hvdn" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    --image) bootstrap_image=$2; shift; shift;;
    -n | --dry-run ) DRY_RUN=true; shift;;
    -v | --verbose ) LOG_LEVEL=INFO; shift ;;
    -d | --debug ) LOG_LEVEL=DEBUG; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# positional arguments
EASY_CONFIGS=$@

mkdir -p /tmp/easybuild/sources

# print some informations
if (( ${levels[$LOG_LEVEL]} <= ${levels["INFO"]} )); then
    for ec in ${EASY_CONFIGS[@]}; do
        cmd="eb ${ec} -Dr"
        log_msg INFO "exec: ${cmd}"
        ${cmd}
    done
    cmd="eb ${EASY_CONFIGS[@]} --dep-graph-layers -r --terse --debug"
    log_msg INFO "exec: ${cmd}"
    ${cmd}
fi

# even with 'terse', eb prints log lines prefixed with '=='
cmd="eb ${EASY_CONFIGS[@]} --dep-graph-layers -r --terse | grep -v '==' > eb_layer_lists.txt"
log_msg INFO "exec: ${cmd}"
${cmd}

previous_layer=
while IFS= read -r layer; do
    IFS=' ' read -r -a ecs <<< "$layer"

    if [ -z "${layer}" ]; then
        log_msg INFO "layer: ${layer}"

        image="$(join_by _ $ecs[@]).sif"

        log_msg INFO "image: ${image}"

        if [ -f "${image}" ]; then
            log_msg INFO "skipped: '${image}' exists already."
        else
            cmd="eb ${layer[@]} --fetch --sourcepath /tmp/easybuild/sources"
            log_msg INFO "exec: ${cmd}"
            if [ -z "${DRY_RUN}" ]; then ${cmd}; fi

            # if previous layer empty, then we are at the beginning of the dependency chain, build new image
            if [ -z "${previous_layer}" ]; then
                cmd="eb -C --container-build-image ${ecs[@]} --container-config bootstrap=library,from=${bootstrap_image} --experimental --force"
                log_msg INFO "exec: ${cmd}"
                if [ -z "${DRY_RUN}" ]; then ${cmd}; fi
            else:
                IFS=' ' read -r -a previous_ecs <<< "$previous_layer"
                previous_image="$(join_by _ ${previous_ecs[@]}).sif"
                cmd="eb -C --container-build-image ${ecs[@]} --container-config bootstrap=localimage,from=${previous_image} --experimental --force"
                log_msg INFO "exec: ${cmd}"
                if [ -z "${DRY_RUN}" ]; then ${cmd}; fi
            fi
        fi
    else
        log_msg INFO "Reached target ${previous_layer}."
    fi
    previous_layer=${layer}
done < eb_layer_lists.txt
