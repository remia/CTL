# Module to find Zlib or to build it if unavailable

# Try to use the default CMake ZLib finder
find_package(ZLIB QUIET NO_CMAKE_ENVIRONMENT_PATH)
if (TARGET ZLIB::ZLIB)
	return()
endif()

# If we got to here, then we need to build ZLib

include(GNUInstallDirs)
include(ExternalProject)
add_library(ZLIB::ZLIB STATIC IMPORTED GLOBAL)
set(ZLIB_MAJOR_VERSION "1")
set(ZLIB_MINOR_VERSION "2")
set(ZLIB_PATCH_VERSION "11")
set(ZLIB_VERSION "${ZLIB_MAJOR_VERSION}.${ZLIB_MINOR_VERSION}.${ZLIB_PATCH_VERSION}")

set(EXT_DIST_ROOT "${CMAKE_BINARY_DIR}/ext/dist")
set(EXT_BUILD_ROOT "${CMAKE_BINARY_DIR}/ext/build")

set(ZLIB_INCLUDE_DIR "${EXT_DIST_ROOT}/include")
# This is hardcoded in zlib, instead of using CMAKE_INSTALL_LIBDIR
# That could be either lib or lib64 depending on the platform
set(ZLIB_LIB_DIR "lib")
set(ZLIB_LIB_PREFIX "${EXT_DIST_ROOT}/${ZLIB_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}")
set(ZLIB_LIB_SUFFIX "${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(ZLIB_LIB_SUFFIX_DEBUG "d${CMAKE_STATIC_LIBRARY_SUFFIX}")

if(UNIX)
	set(ZLIB_STATIC_LIB_NAME "z")
else()
	set(ZLIB_STATIC_LIB_NAME "zlibstatic")
endif()

set(ZLIB_LIBRARY "${ZLIB_LIB_PREFIX}${ZLIB_STATIC_LIB_NAME}${ZLIB_LIB_SUFFIX}")
set(ZLIB_LIBRARY_DEBUG "${ZLIB_LIB_PREFIX}${ZLIB_STATIC_LIB_NAME}${ZLIB_LIB_SUFFIX_DEBUG}")

set(ZLIB_CMAKE_ARGS
	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
	#-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
	-DCMAKE_INSTALL_PREFIX=${EXT_DIST_ROOT}
	-DBUILD_SHARED_LIBS=OFF
)
file(MAKE_DIRECTORY ${ZLIB_INCLUDE_DIR})

ExternalProject_Add(ZLIB_BUILD
	GIT_REPOSITORY "https://github.com/madler/zlib.git"
	GIT_TAG "v${ZLIB_VERSION}"
	GIT_SHALLOW TRUE
	PREFIX "${EXT_BUILD_ROOT}/zlib"
	CMAKE_ARGS ${ZLIB_CMAKE_ARGS}
	UPDATE_COMMAND "" # Skip re-checking the tag every build
	BUILD_COMMAND
		${CMAKE_COMMAND} --build .
						 --config $<CONFIG>
						 --target zlibstatic
	COMMAND
		${CMAKE_COMMAND} --build .
						 --config $<CONFIG>
						 --target zlib
	INSTALL_COMMAND
		${CMAKE_COMMAND} -DBUILD_TYPE=$<CONFIG> -P "cmake_install.cmake"
	EXCLUDE_FROM_ALL TRUE
)

add_dependencies(ZLIB::ZLIB ZLIB_BUILD)
set_target_properties(ZLIB::ZLIB
	PROPERTIES
		IMPORTED_LOCATION ${ZLIB_LIBRARY}
		IMPORTED_LOCATION_DEBUG ${ZLIB_LIBRARY_DEBUG}
		INTERFACE_INCLUDE_DIRECTORIES ${ZLIB_INCLUDE_DIR}
)
