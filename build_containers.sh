#!/bin/bash
set -euo pipefail

bootstrap_image="shahzebmsiddiqui/default/easybuild:centos-7"

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOG_LEVEL="WARN"
DRY_RUN=

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

mkdir -p "$(pwd)/sources"
mkdir -p /tmp/easybuild/
ln -sf "$(pwd)/sources" /tmp/easybuild/sources

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
cmd="eb ${EASY_CONFIGS[@]} --dep-graph-layers -r --terse"
log_msg INFO "exec: ${cmd}"
${cmd} | grep -v '==' > eb_layer_lists.txt

previous_layer=
while IFS= read -r layer; do
    if [ -n "${layer}" ]; then
        IFS=' ' read -r -a ecs <<< "$layer"
        log_msg INFO "layer: ${layer}"

        ec_basenames=$(for ec in "${ecs[@]}"; do basename "$ec" ".eb"; done)
        image_name="$(join_by _ ${ec_basenames[@]})"
        image_file="${image_name}.sif"

        log_msg INFO "image: ${image_file}"

        if [ -f "${image_file}" ]; then
            log_msg INFO "skipped: '${image}' exists already."
        else
            cmd="eb ${layer[@]} --fetch --sourcepath /tmp/easybuild/sources"
            log_msg INFO "exec: ${cmd}"
            if [ -z "${DRY_RUN}" ]; then ${cmd}; fi

            # if previous layer empty, then we are at the beginning of the dependency chain, build new image
            if [ -z "${previous_layer}" ]; then
                cmd="eb -C --container-build-image ${ecs[@]} --containerpath $(pwd) \
                    --container-config bootstrap=library,from=${bootstrap_image},eb_args='-l' \
                    --experimental --force --container-image-name ${image_name} \
                    --container-image-format sif --container-tmpdir ${SINGULARITY_TMPDIR}"
                log_msg INFO "exec: ${cmd}"
                if [ -z "${DRY_RUN}" ]; then ${cmd}; fi
            else
                IFS=' ' read -r -a previous_ecs <<< "$previous_layer"
                previous_ec_basenames=$(for ec in "${previous_ecs[@]}"; do basename "$ec" ".eb"; done)
                previous_image_name="$(join_by _ ${previous_ec_basenames[@]})"
                previous_image_file="${previous_image_name}.sif"
                cmd="eb -C --container-build-image ${ecs[@]} --containerpath $(pwd) \
                    --container-config bootstrap=localimage,from=${previous_image_file},eb_args='-l' \
                    --experimental --force --container-image-name ${image_name} \
                    --container-image-format sif --container-tmpdir ${SINGULARITY_TMPDIR}"
                log_msg INFO "exec: ${cmd}"
                if [ -z "${DRY_RUN}" ]; then ${cmd}; fi
            fi
        fi
    else
        log_msg INFO "Reached target ${previous_layer}."
    fi
    previous_layer=${layer}
done < eb_layer_lists.txt
