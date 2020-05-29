# export SOFTWAREROOT=$HOME/software
export STAGE=2019a

prefix=${HOME}/.local/easybuild
buidlpath=${prefix}/build
container_path=${prefix}/containers
install_path=${prefix}/easybuild
repository_path=${prefix}/ebfiles_repo
# robot_paths=${HOME}/.local/easybuild/software/EasyBuild/4.2.1/easybuild/easyconfigs
sources_path=${prefix}/sources

# software_root=${SOFTWAREROOT}
stage=${STAGE}
# stage_path="${software_root}/Stages/${stage}"
# sources_path="${HOME}/eb/sources"

common_eb_path="${HOME}/git"
common_jsc_eb_path="${HOME}/git/JSC"
gr_path="${common_eb_path}/easybuild-easyconfigs/easybuild/easyconfigs"
jsc_gr_path="${common_jsc_eb_path}/Golden_Repo/${stage}"
custom_easyblocks_path="${common_jsc_eb_path}/Custom_EasyBlocks/${stage}"
custom_toolchains_path="${common_jsc_eb_path}/Custom_Toolchains/${stage}"
custom_mns_path="${common_jsc_eb_path}/Custom_MNS/${stage}"

export EASYBUILD_ROBOT=${gr_path}
export EASYBUILD_ROBOT_PATHS=${gr_path}:${jsc_gr_path}
export EASYBUILD_DETECT_LOADED_MODULES=error
export EASYBUILD_ALLOW_LOADED_MODULES=EasyBuild
export EASYBUILD_SOURCEPATH=${sources_path}
export EASYBUILD_INSTALLPATH=${install_path}
export EASYBUILD_BUILDPATH=/dev/shm
export EASYBUILD_INCLUDE_TOOLCHAINS="${custom_toolchains_path}/*.py,${custom_toolchains_path}/fft/*.py,${custom_toolchains_path}/compiler/*.py"
# export EASYBUILD_INCLUDE_EASYBLOCKS="${custom_easyblocks_path}/*.py"
export EASYBUILD_REPOSITORY=FileRepository
export EASYBUILD_REPOSITORYPATH=${repository_path}
export EASYBUILD_SET_GID_BIT=1
export EASYBUILD_MODULES_TOOL=Lmod
export EASYBUILD_MODULE_SYNTAX=Lua
export EASYBUILD_PREFIX=${prefix}
export EASYBUILD_INCLUDE_MODULE_NAMING_SCHEMES="${custom_mns_path}/*.py"
export EASYBUILD_MODULE_NAMING_SCHEME=FlexibleCustomHierarchicalMNS
export EASYBUILD_FIXED_INSTALLDIR_NAMING_SCHEME=1
export EASYBUILD_EXPERIMENTAL=1
export EASYBUILD_MINIMAL_TOOLCHAINS=1
export EASYBUILD_USE_EXISTING_MODULES=1
# export EASYBUILD_TEST_REPORT_ENV_FILTER="\*PS1\*|PROMPT\*|\*LICENSE\*"
