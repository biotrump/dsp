#!/bin/bash
# Compiles ffts for Android
#build_NDK_cmake.sh [arm|x86]
if [ $# -eq 0 ]; then
	echo "$0 [arm|x86]"
	exit
fi

#export CMAKE_BUILD_TYPE "Debug"
export CMAKE_BUILD_TYPE="Release"

#get cpu counts
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

#project dependant sources
export DSP_HOME=${DSP_HOME:-`pwd`}
export BLIS_SRC=${DSP_HOME}/blis
#armv7a
export BLISLIB_DIR=${BLISLIB_DIR:-${BLIS_SRC}/lib/armv7a}
#libblis.a
export BLIS_LIB_NAME=${BLIS_LIB_NAME:-blis}

export FFTS_DIR=${DSP_HOME}/ffts
export FFTS_LIB_DIR=${FFTS_DIR}/lib
#libffts-arm.a
FFTS_LIB_NAME=ffts-arm

export LAPACK_SRC=${LAPACK_SRC:-${DSP_HOME}/LAPACK}
export LAPACK_BUILD=${LAPACK_BUILD:-${LAPACK_SRC}/build_and}
export LAPACK_LIB=${LAPACK_LIB:-${LAPACK_BUILD}/lib}
export LAPACKE_SRC=${LAPACKE_SRC:-${LAPACK_SRC}/LAPACKE}
export CBLAS_SRC=${CBLAS_SRC:-${LAPACK_SRC}/CBLAS}

# Make sure you have NDK_ROOT defined in .bashrc or .bash_profile
# Modify INSTALL_DIR to suit your situation
#Lollipop	5.0 - 5.1	API level 21, 22
#KitKat	4.4 - 4.4.4	API level 19
#Jelly Bean	4.3.x	API level 18
#Jelly Bean	4.2.x	API level 17
#Jelly Bean	4.1.x	API level 16
#Ice Cream Sandwich	4.0.3 - 4.0.4	API level 15, NDK 8
#Ice Cream Sandwich	4.0.1 - 4.0.2	API level 14, NDK 7
#Honeycomb	3.2.x	API level 13
#Honeycomb	3.1	API level 12, NDK 6
#Honeycomb	3.0	API level 11
#Gingerbread	2.3.3 - 2.3.7	API level 10
#Gingerbread	2.3 - 2.3.2	API level 9, NDK 5
#Froyo	2.2.x	API level 8, NDK 4

export NDK_ROOT=${HOME}/NDK/android-ndk-r10d
#gofortran is supported in r9
#export NDK_ROOT=${HOME}/NDK/android-ndk-r9
export ANDROID_NDK=${NDK_ROOT}

if [[ ${NDK_ROOT} =~ .*"-r9".* ]]
then
#ANDROID_APIVER=android-8
#ANDROID_APIVER=android-9
#android 4.0.1 ICS and above
ANDROID_APIVER=android-14
#TOOL_VER="4.6"
#gfortran is in r9d V4.8.0
TOOL_VER="4.8.0"
else
#android 4.0.1 ICS and above
ANDROID_APIVER=android-14
TOOL_VER="4.9"
fi

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

#NDK cross compile toolchains
#the first parameter is x86 or arm
case $1 in
  arm)
    TARGPLAT=arm-linux-androideabi
    CONFTARG=arm-eabi
    ARCHI=arm
  ;;
  x86)
    TARGPLAT=i686-linux-android
    CONFTARG=x86
    ARCHI=x86
  ;;
  mips)
  ## probably wrong
    TARGPLAT=mipsel-linux-android
    CONFTARG=mips
    ARCHI=mips
  ;;
  *) echo $0: Unknown target; exit
esac
echo ARCHI=$ARCHI

#export NDK
#: ${NDK_ROOT:?}

echo "Using: $NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin"
export ARCHI
#export PATH="$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:\
#$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/${TARGPLAT}/bin/:$PATH"
export PATH="${NDK_ROOT}/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:$PATH"
echo $PATH
export SYS_ROOT="${NDK_ROOT}/platforms/${ANDROID_APIVER}/arch-${ARCHI}/"
export CC="${TARGPLAT}-gcc --sysroot=$SYS_ROOT"
export LD="${TARGPLAT}-ld"
export AR="${TARGPLAT}-ar"
export ARCH=${AR}
export RANLIB="${TARGPLAT}-ranlib"
export STRIP="${TARGPLAT}-strip"
#export CFLAGS="-Os -fPIE"
export CFLAGS="-Os -fPIE --sysroot=$SYS_ROOT"
export CXXFLAGS="-fPIE --sysroot=$SYS_ROOT"
export FORTRAN="${TARGPLAT}-gfortran --sysroot=$SYS_ROOT"

#!!! quite importnat for cmake to define the NDK's fortran compiler.!!!
#Don't let cmake decide it.
export FC=${FORTRAN}

#checking build folder
if [ ! -d build_and ]; then
mkdir build_and
fi
cd build_and
if [ ! -d ${ARCHI}-${CMAKE_BUILD_TYPE} ]; then
mkdir ${ARCHI}-${CMAKE_BUILD_TYPE}
fi

rm -rf ${ARCHI}-${CMAKE_BUILD_TYPE}/*

cd ${ARCHI}-${CMAKE_BUILD_TYPE}
pwd
#cmake and build
cmake -DANDROID_NDK=${NDK_ROOT} -DANDROID_TOOLCHAIN_NAME=${TARGPLAT}-${TOOL_VER} \
-DCMAKE_BUILD_TYPE=Release -DANDROID_ABI="armeabi-v7a with VFPV3" \
-DFFTS_DIR:FILEPATH=${FFTS_DIR} -DFFTS_LIB_DIR:FILEPATH=${FFTS_LIB_DIR} \
-DFFTS_LIB_NAME=${FFTS_LIB_NAME} \
-DLAPACK_SRC:FILEPATH=${LAPACK_SRC} -DLAPACK_BUILD:FILEPATH=${LAPACK_BUILD} \
-DLAPACK_LIB:FILEPATH=${LAPACK_LIB} -DLAPACKE_SRC:FILEPATH=${LAPACKE_SRC} \
-DUSE_BLIS=1 -DBLIS_SRC:FILEPATH=${BLIS_SRC} -DBLISLIB_DIR:FILEPATH=${BLISLIB_DIR} \
-DBLIS_LIB_NAME=${BLIS_LIB_NAME} \
-DCBLAS_SRC:FILEPATH=${CBLAS_SRC} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
${DSP_HOME}

#make -j${CORE_COUNT}
