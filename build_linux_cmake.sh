#!/bin/bash
#Thomas Tsai <thomas@biotrump.com>
#export CMAKE_BUILD_TYPE "Debug"
export CMAKE_BUILD_TYPE="Release"

if [ -z "${MAKE_FLAGS}" ];then
case $(uname -s) in
  Darwin)
    CONFBUILD=i386-apple-darwin`uname -r`
    HOSTPLAT=darwin-x86
    CORE_COUNT=`sysctl -n hw.ncpu`
  ;;
  Linux)
    CONFBUILD=x86-unknown-linux
    HOSTPLAT=linux-`uname -m`
    CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
  ;;
CYGWIN*)
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
  *) echo $0: Unknown platform; exit
esac
export MAKE_FLAGS="-j${CORE_COUNT}"
fi

if [ -z "$DSP_HOME" ];then
	echo "No shell ENVS are exported from .config by setup.sh"
	echo "so export it again by ../setup.sh"
	pushd ..
	if [ -f .config ];then
	. setup.sh
	else
		echo `pwd`/.config does not exist, exit!
		exit -1
	fi
	popd
	exit
	#export DSP_HOME=${DSP_HOME:-`pwd`}
	#export ATLAS_SRC=${DSP_HOME}/ATLAS
	#export ATLAS_OUT=${ATLAS_SRC}/build_x86
	#export LAPACK_SRC=${LAPACK_SRC:-${DSP_HOME}/LAPACK}
	export LAPACK_BUILD=${LAPACK_BUILD:-${LAPACK_SRC}/build-x86}
	export LAPACK_LIB=${LAPACK_LIB:-${LAPACK_BUILD}/lib}
	export LAPACKE_SRC=${LAPACKE_SRC:-${LAPACK_SRC}/LAPACKE}
	export CBLAS_SRC=${CBLAS_SRC:-${LAPACK_SRC}/CBLAS}
	#export BUILD_HOME=${BUILD_HOME:-$HOME/build}

	export BLIS_SRC=${DSP_HOME}/blis
	export BLISLIB=${BLISLIB:-${BLIS_SRC}/lib/sandybridge/libblis.a}
	#x86
	export BLISLIB_DIR=${BLISLIB_DIR:-${BLIS_SRC}/lib/sandybridge}
	#libblis.a
	export BLIS_LIB_NAME=${BLIS_LIB_NAME:-blis}

	#export FFTS_DIR=${DSP_HOME}/ffts
	export FFTS_LIB_DIR=${FFTS_DIR}/lib
	#libffts-x86.a
	export FFTS_LIB_NAME=ffts-x86
fi

if [ ! -d build_x86 ]; then
mkdir build_x86
fi
cd build_x86
if [ ! -d ${CMAKE_BUILD_TYPE} ]; then
mkdir ${CMAKE_BUILD_TYPE}
fi
rm -rf ${CMAKE_BUILD_TYPE}/*

pushd ${CMAKE_BUILD_TYPE}

cmake -DFFTS_DIR:FILEPATH=${FFTS_DIR} \
-DATLAS_SRC:FILEPATH=${ATLAS_SRC} -DATLAS_OUT:FILEPATH=${ATLAS_OUT} \
-DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DFFTS_LIB_NAME=${FFTS_LIB_NAME} -DHAVE_SSE=1 ${DSP_HOME}

#-DLAPACK_SRC:FILEPATH=${LAPACK_SRC} -DLAPACK_BUILD:FILEPATH=${LAPACK_BUILD} \
#-DLAPACK_LIB:FILEPATH=${LAPACK_LIB} -DLAPACKE_SRC:FILEPATH=${LAPACKE_SRC} \
#-DCBLAS_SRC:FILEPATH=${CBLAS_SRC} ..

make ${MAKE_FLAGS} $@

popd
