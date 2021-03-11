# Module to find Imath or to build it if unavailable

find_package(Imath QUIET CONFIG)
if (NOT TARGET Imath::Imath)
	# Maybe an older version of IlmBase exists?
	find_package(IlmBase QUIET CONFIG)
	if(TARGET IlmBase::Imath)
		# Was failing with cmake 3.17, works in 3.19.6
		# CMake Error at cmake/modules/FindImath.cmake:8 (add_library):
		#   add_library cannot create ALIAS target "Imath::Imath" because target
		#   "IlmBase::Imath" is imported but not globally visible.
		# Call Stack (most recent call first):
		#   CMakeLists.txt:14 (find_package)
		add_library(Imath::Imath ALIAS IlmBase::Imath)
		add_library(Imath::Half ALIAS IlmBase::Half)
	endif()
endif()

if(TARGET Imath::Imath)
	return()
endif()

# If we got to here, then we need to build Imath
find_package(ZLIB QUIET REQUIRED)
include(GNUInstallDirs)
include(ExternalProject)
add_library(Imath::Imath STATIC IMPORTED GLOBAL)
add_library(Imath::Half STATIC IMPORTED GLOBAL)
set(OPENEXR_MAJOR_VERSION "2")
set(OPENEXR_MINOR_VERSION "5")
set(OPENEXR_PATCH_VERSION "5")
set(OPENEXR_VERSION "${OPENEXR_MAJOR_VERSION}.${OPENEXR_MINOR_VERSION}.${OPENEXR_PATCH_VERSION}")

set(EXT_DIST_ROOT "${CMAKE_BINARY_DIR}/ext/dist")
set(EXT_BUILD_ROOT "${CMAKE_BINARY_DIR}/ext/build")

set(IMATH_INCLUDE_DIR "${EXT_DIST_ROOT}/include/OpenEXR")
set(IMATH_LIB_PREFIX "${EXT_DIST_ROOT}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}")
set(IMATH_LIB_SUFFIX "-${OPENEXR_MAJOR_VERSION}_${OPENEXR_MINOR_VERSION}${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(IMATH_LIB_SUFFIX_DEBUG "-${OPENEXR_MAJOR_VERSION}_${OPENEXR_MINOR_VERSION}_d${CMAKE_STATIC_LIBRARY_SUFFIX}")

set(IMATH_LIBRARY "${IMATH_LIB_PREFIX}Imath${IMATH_LIB_SUFFIX}")
set(IMATH_LIBRARY_DEBUG "${IMATH_LIB_PREFIX}Imath${IMATH_LIB_SUFFIX_DEBUG}")
set(HALF_LIBRARY "${IMATH_LIB_PREFIX}Half${IMATH_LIB_SUFFIX}")
set(HALF_LIBRARY_DEBUG "${IMATH_LIB_PREFIX}Half${IMATH_LIB_SUFFIX_DEBUG}")

set(IMATH_CMAKE_ARGS
	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
	#-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
	-DCMAKE_INSTALL_PREFIX=${EXT_DIST_ROOT}
	-DBUILD_SHARED_LIBS=OFF
	-DBUILD_TESTING=OFF
	-DPYILMBASE_ENABLE=OFF
)
file(MAKE_DIRECTORY ${IMATH_INCLUDE_DIR})

ExternalProject_Add(IMATH_BUILD
	GIT_REPOSITORY "https://github.com/AcademySoftwareFoundation/openexr.git"
	GIT_TAG "v${OPENEXR_VERSION}"
	GIT_SHALLOW TRUE
	PREFIX "${EXT_BUILD_ROOT}/imath"
	CMAKE_ARGS ${IMATH_CMAKE_ARGS}
	UPDATE_COMMAND "" # Skip re-checking the tag every build
	BUILD_COMMAND
		${CMAKE_COMMAND} --build .
						 --config $<CONFIG>
						 --target Imath
	COMMAND
		${CMAKE_COMMAND} --build .
						 --config $<CONFIG>
						 --target Half
	INSTALL_COMMAND
		${CMAKE_COMMAND} -DBUILD_TYPE=$<CONFIG> -P "IlmBase/Imath/cmake_install.cmake"
	COMMAND
	${CMAKE_COMMAND} -DBUILD_TYPE=$<CONFIG> -P "IlmBase/Half/cmake_install.cmake"
	COMMAND
		${CMAKE_COMMAND} -DBUILD_TYPE=$<CONFIG> -P "IlmBase/config/cmake_install.cmake"
	EXCLUDE_FROM_ALL TRUE
)
add_dependencies(IMATH_BUILD ZLIB::ZLIB)

add_dependencies(Imath::Imath IMATH_BUILD)
set_target_properties(Imath::Imath
	PROPERTIES
		IMPORTED_LOCATION ${IMATH_LIBRARY}
		IMPORTED_LOCATION_DEBUG ${IMATH_LIBRARY_DEBUG}
		INTERFACE_INCLUDE_DIRECTORIES ${IMATH_INCLUDE_DIR}
)
add_dependencies(Imath::Half IMATH_BUILD)
set_target_properties(Imath::Half
	PROPERTIES
		IMPORTED_LOCATION ${HALF_LIBRARY}
		IMPORTED_LOCATION_DEBUG ${HALF_LIBRARY_DEBUG}
		INTERFACE_INCLUDE_DIRECTORIES ${IMATH_INCLUDE_DIR}
)
