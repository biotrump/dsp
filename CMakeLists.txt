#http://stackoverflow.com/questions/11429055/cmake-how-create-a-single-shared-library-from-all-static-libraries-of-subprojec
cmake_minimum_required(VERSION 2.8.10)
project(DSP C CXX)
set(DSP_VERSION 0.8)

#DSP_SOURCE_DIR == CMAKE_SOURCE_DIR
message("CMAKE_SOURCE_DIR : ${CMAKE_SOURCE_DIR}")
message("PROJECT_NAME : ${PROJECT_NAME}")
message("DSP_SOURCE_DIR : ${DSP_SOURCE_DIR}")
message("DSP_BINARY_DIR : ${DSP_BINARY_DIR}")
#${PROJECT_NAME} : Name of the "project" given to the project command.
#${DSPLIB_SOURCE_DIR} : path of the "project" source given to the project command.
#${DSPLIB_BINARY_DIR} : path of the "project" binary given to the project command.
# --------------------------------------------------
#In order to see the symbols from the static library, use:
set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--export-all-symbols")

# --------------------------------------------------
# Organize output files.  On Windows this also keeps .dll files next
# to the .exe files that need them, making tests easy to run.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/lib)

if(NOT "${BCV_ENV_EXPORTED}" STREQUAL "1")
#all shell ENVs are not exported!
	include(../cmake/CVEnvImport.cmake)
	UNSET(BCV_ENV_EXPORTED CACHE)
	set(BCV_ENV_EXPORTED "1")
	message("******MAKE_FLAGS=${MAKE_FLAGS}")
endif()

# --------------------------------------------------
#find ffts
# --------------------------------------------------
message("FFTS_DIR=${FFTS_DIR}")
if("${FFTS_DIR}" STREQUAL "")
	set(FFTS_DIR "${DSP_SOURCE_DIR}/ffts")
	message("set FFTS_DIR=${FFTS_DIR}")
endif()

find_path(FFTS_INC ffts.h
			HINTS ${FFTS_DIR}/include )
message("FFTS_INC=${FFTS_INC}" )
if(FFTS_INC)
	include_directories("${FFTS_INC}")
endif(FFTS_INC)

if(ANDROID_NDK)
	#rebuld ffts
	if ( "${ANDROID_ABI}" MATCHES "armeabi" )
		add_custom_target ( libffts
			COMMAND bash ./build_NDK.sh arm
			WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )
	elseif ("${ANDROID_ABI}" MATCHES "x86")
		add_custom_target ( libffts
			COMMAND bash ./build_NDK.sh x86
			WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )
	elseif ("${ANDROID_ABI}" MATCHES "mips")
		add_custom_target ( libffts
			COMMAND bash ./build_NDK.sh mips
			WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )
	endif ()

else(ANDROID_NDK)
	#clean libffts if necessary
#	add_custom_target ( libffts_clean
#		COMMAND rm -rf build_${TARGET_ARCH}/*
#		WORKING_DIRECTORY ${FFTS_DIR} )

	#rebuld ffts
#	add_custom_target ( libffts
#		COMMAND bash ./build_x86.sh
#		WORKING_DIRECTORY ${FFTS_DIR} )

endif(ANDROID_NDK)

# --------------------------------------------------
#ATLAS for x86 only
# --------------------------------------------------
if("${ATLAS_SRC}" STREQUAL "")
	set(ATLAS_SRC "${DSP_SOURCE_DIR}/ATLAS")
	message("set ATLAS_SRC=${ATLAS_SRC}")
endif()

if(NOT ANDROID_NDK)
#	add_custom_target ( atlas_clean
#		COMMAND make clean
#		WORKING_DIRECTORY ${ATLAS_OUT} )

#	add_custom_target ( atlas_x86 ALL
#		COMMAND bash ./atlas_x86.sh config
#		COMMAND bash ./atlas_x86.sh build
#		WORKING_DIRECTORY ${ATLAS_SRC} )

#x86 : ATLAS library
	message("***find atlas")
	set(ATLAS_LIB "lapacke;lapack;f77refblas;cblas;f77blas;ptlapack;ptf77blas;ptcblas;tstatlas;atlas")
	#check if any lib does not exist. If anyone does not exist, rebuild it!
	foreach(alib ${ATLAS_LIB})
		UNSET(ATLASLIB CACHE)
		find_library (ATLASLIB
					NAMES ${alib}
					PATHS ${ATLAS_OUT}/lib
					PATH_SUFFIXES lib
					NO_DEFAULT_PATH)
		message("ATLASLIB=${ATLASLIB} ")
	endforeach(alib)

	find_path(ATLAS_INC atlas_f77.h
				HINTS ${ATLAS_SRC}/include )
	message("ATLAS_INC=${ATLAS_INC}" )
	if(ATLAS_INC)
		include_directories("${ATLAS_INC}")
	endif(ATLAS_INC)
endif(NOT ANDROID_NDK)
# --------------------------------------------------
#dsp/lib
#build the final static .a or shared .so
# --------------------------------------------------
message("DSPLIB_DIR=${DSPLIB_DIR}")
if("${DSPLIB_DIR}" STREQUAL "")
	set(DSPLIB_DIR "${DSP_SOURCE_DIR}/lib")
	message("set DSPLIB_DIR=${DSPLIB_DIR}")
endif()

find_path(DSPLIB_INC dsp-lib.h
			HINTS ${DSPLIB_DIR} )
message("DSPLIB_INC=${DSPLIB_INC}" )
if(DSPLIB_INC)
	include_directories("${DSPLIB_INC}")
endif(DSPLIB_INC)

if(ANDROID_NDK)
#android

	if ( "${ANDROID_ABI}" MATCHES "armeabi" )
		add_custom_target ( libdsp
		COMMAND bash ./build_NDK_cmake.sh arm
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/lib )

	elseif ("${ANDROID_ABI}" MATCHES "x86")
		add_custom_target ( libdsp
		COMMAND bash ./build_NDK_cmake.sh x86
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/lib )

	elseif ("${ANDROID_ABI}" MATCHES "mips")
		add_custom_target ( libdsp
		COMMAND bash ./build_NDK_cmake.sh mips
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/lib )
	endif ()

else(ANDROID_NDK)
#x86
	add_custom_target ( libdsp
		COMMAND bash ./build_x86_cmake.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/lib )

endif(ANDROID_NDK)
# --------------------------------------------------
#add_executable ( MyProjectOutput ctags.output )
#add_library(${PROJECT_NAME} OBJECT ${SRC})
#x86
#add_subdirectory(ATLAS)
#add_subdirectory(blis)
#add_subdirectory(ffts)
#add_subdirectory(LAPACK)
##add_subdirectory(clapack)
#add_subdirectory(lib dsp-lib)
##add_subdirectory(libflame)

# --------------------------------------------------
add_executable(dsp-dummy
  dummy.c
)

if(ANDROID_NDK)
		add_dependencies(dsp-dummy
		libffts
		)
else(ANDROID_NDK)
		add_dependencies(dsp-dummy
		libffts
		atlas_x86
		libdsp
		)
endif(ANDROID_NDK)

