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
#ATLAS
option(BUILD_ATLAS_LIBS "Whether or not to build ATLAS library for x86" OFF)
add_custom_target ( atlas_clean
	COMMAND make clean
	WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ATLAS/build_x86 )

if(NOT ANDROID_NDK AND NOT BUILD_ATLAS_LIBS)
#x86 : ATLAS library
	message("***find atlas")
	set(ATLAS_LIB "lapacke;lapack;f77refblas;cblas;f77blas;ptlapack;ptf77blas;ptcblas;tstatlas;atlas")
	#check if any lib does not exist. If anyone does not exist, rebuild it!
	foreach(alib ${ATLAS_LIB})
		UNSET(ATLASLIB CACHE)
		find_library (ATLASLIB
					NAMES ${alib}
					PATHS ${DSP_SOURCE_DIR}/ATLAS/build_x86/lib
					PATH_SUFFIXES lib
					NO_DEFAULT_PATH)
		message("ATLASLIB=${ATLASLIB} ")
		if(NOT ATLASLIB)
			set(BUILD_ATLAS_LIBS "ON")
		endif(NOT ATLASLIB)
	endforeach(alib)
endif(NOT ANDROID_NDK AND NOT BUILD_ATLAS_LIBS)

message("BUILD_ATLAS_LIBS=${BUILD_ATLAS_LIBS}")
if(BUILD_ATLAS_LIBS)
	add_custom_target ( atlas_x86 ALL
		COMMAND ./atlas_x86.sh config
		COMMAND ./atlas_x86.sh build
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ATLAS )

endif(BUILD_ATLAS_LIBS)

# --------------------------------------------------
if(NOT ANDROID_NDK)
	find_path(ATLAS_INC cblas.h
				HINTS ${DSP_SOURCE_DIR}/ATLAS/include )
	message("ATLAS_INC=${ATLAS_INC}" )
	if(ATLAS_INC)
		include_directories("${ATLAS_INC}")
	endif(ATLAS_INC)
endif(NOT ANDROID_NDK)

# --------------------------------------------------
#find ffts
find_path(FFTS_INC ffts.h
			HINTS ${DSP_SOURCE_DIR}/ffts/include )
message("FFTS_INC=${FFTS_INC}" )
if(FFTS_INC)
	include_directories("${FFTS_INC}")
endif(FFTS_INC)

#message("FFTS_LIB_DIR=${FFTS_LIB_DIR} ")
#clean libffts if necessary
add_custom_target ( libffts_clean
	COMMAND make clean
	COMMAND git clean -f -d
	COMMAND	git reset --hard
	WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )

if(ANDROID_NDK)
#rebuld ffts
	add_custom_target ( libffts
		COMMAND git clean -f -d
		COMMAND	git reset --hard
		COMMAND ./build_android.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )

else(ANDROID_NDK)

	#rebuld ffts
	add_custom_target ( libffts
		COMMAND git clean -f -d
		COMMAND	git reset --hard
		COMMAND ./build_x86.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/ffts )

endif(ANDROID_NDK)

# --------------------------------------------------
#find blis
#clean libffts if necessary
add_custom_target ( blis_clean
	COMMAND make clean
	COMMAND git clean -f -d
	COMMAND	git reset --hard
	WORKING_DIRECTORY ${DSP_SOURCE_DIR}/blis )

if(ANDROID_NDK)
	add_custom_target ( libblis
#		COMMAND git clean -f -d
#		COMMAND	git reset --hard
		COMMAND ./build_android.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/blis )

else(ANDROID_NDK)
#x86
	#rebuld libblis
	add_custom_target ( libblis
#		COMMAND git clean -f -d
#		COMMAND	git reset --hard
		COMMAND ./build_x86.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/blis )
endif(ANDROID_NDK)

# --------------------------------------------------
#find LAPACK
if(ANDROID_NDK)
#android
	add_custom_target ( lapack
#		COMMAND git clean -f -d
#		COMMAND	git reset --hard
		COMMAND ./build_android_cmake.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/LAPACK )

else(ANDROID_NDK)
#x86
	#rebuld ffts
	add_custom_target ( lapack
#		COMMAND git clean -f -d
#		COMMAND	git reset --hard
		COMMAND ./build_x86_cmake.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/LAPACK )
endif(ANDROID_NDK)
# --------------------------------------------------
if(ANDROID_NDK)
#android
	add_custom_target ( libdsp
		COMMAND ./build_android_cmake.sh
		WORKING_DIRECTORY ${DSP_SOURCE_DIR}/lib )

else(ANDROID_NDK)
#x86
	#rebuld ffts
	add_custom_target ( libdsp
		COMMAND ./build_x86_cmake.sh
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
#add_subdirectory(lib)
##add_subdirectory(libflame)

#In order to see the symbols from the static library, use:
set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--export-all-symbols")

# --------------------------------------------------

# Organize output files.  On Windows this also keeps .dll files next
# to the .exe files that need them, making tests easy to run.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${DSP_BINARY_DIR}/lib)
# --------------------------------------------------
#x86.so
#add_library(${PROJECT_NAME} SHARED $<TARGET_OBJECTS:lib>
#                                   $<TARGET_OBJECTS:ffts>
#                                   $<TARGET_OBJECTS:ATLAS>
#                                   )

#add_library(${PROJECT_NAME} SHARED	$<TARGET_OBJECTS:ATLAS>
#                                   )
add_executable(dummy
  dummy.c
)

add_dependencies(dummy libffts)
add_dependencies(dummy libblis)
if(BUILD_ATLAS_LIBS)
add_dependencies(dummy atlas_x86)
endif(BUILD_ATLAS_LIBS)
add_dependencies(dummy lapack)
add_dependencies(dummy libdsp)

#arm.so
#add_library(${PROJECT_NAME} SHARED $<TARGET_OBJECTS:lib>
#                                   $<TARGET_OBJECTS:ffts>
#                                   $<TARGET_OBJECTS:blis>
#                                   $<TARGET_OBJECTS:LAPACK>
#                                   )

#executable
#add_executable(name_of_executable 	$<TARGET_OBJECTS:subproject1>
#									$<TARGET_OBJECTS:subproject2>)
#set(LINK_FLAGS ${LINK_FLAGS} "-Wl,-whole-archive")
#target_link_libraries(name_of_executable ${PROJECT_NAME}