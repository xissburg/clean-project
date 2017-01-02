#/*
#-----------------------------------------------------------------------------
#Filename:    common.cmake
#-----------------------------------------------------------------------------
#
#This source file is part of the
#   ___                 __    __ _ _    _
#  /___\__ _ _ __ ___  / / /\ \ (_) | _(_)
# //  // _` | '__/ _ \ \ \/  \/ / | |/ / |
#/ \_// (_| | | |  __/  \  /\  /| |   <| |
#\___/ \__, |_|  \___|   \/  \/ |_|_|\_\_|
#      |___/
#      Tutorial Framework
#      http://www.ogre3d.org/tikiwiki/
#-----------------------------------------------------------------------------
#*/

project(${APP})

if(WIN32)
	set(CMAKE_MODULE_PATH "$ENV{OGRE_HOME}/CMake/;${CMAKE_MODULE_PATH}")
	set(OGRE_SAMPLES_INCLUDEPATH "$ENV{OGRE_HOME}/Samples/include")
endif(WIN32)

if (CMAKE_BUILD_TYPE STREQUAL "")
  # CMake defaults to leaving CMAKE_BUILD_TYPE empty. This screws up
  # differentiation between debug and release builds.
  set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Choose the type of build, options are: None (CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

set(CMAKE_DEBUG_POSTFIX "_d")

set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/dist")

find_package(OGRE REQUIRED)

find_package(OIS REQUIRED)

if(NOT OIS_FOUND)
	message(SEND_ERROR "Failed to find OIS.")
endif()

# Find Boost
if (NOT OGRE_BUILD_PLATFORM_IPHONE)
	if (WIN32 OR APPLE)
		set(Boost_USE_STATIC_LIBS TRUE)
	else ()
		# Statically linking boost to a dynamic Ogre build doesn't work on Linux 64bit
		set(Boost_USE_STATIC_LIBS ${OGRE_STATIC})
	endif ()
	if (MINGW)
		# this is probably a bug in CMake: the boost find module tries to look for
		# boost libraries with name libboost_*, but CMake already prefixes library
		# search names with "lib". This is the workaround.
		set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} "")
	endif ()
	set(Boost_ADDITIONAL_VERSIONS "1.44" "1.44.0" "1.42" "1.42.0" "1.41.0" "1.41" "1.40.0" "1.40" "1.39.0" "1.39" "1.38.0" "1.38" "1.37.0" "1.37" )
	# Components that need linking (NB does not include header-only components like bind)
	set(OGRE_BOOST_COMPONENTS thread date_time)
	find_package(Boost COMPONENTS ${OGRE_BOOST_COMPONENTS} QUIET)
	if (NOT Boost_FOUND)
		# Try again with the other type of libs
		set(Boost_USE_STATIC_LIBS NOT ${Boost_USE_STATIC_LIBS})
		find_package(Boost COMPONENTS ${OGRE_BOOST_COMPONENTS} QUIET)
	endif()
	find_package(Boost QUIET)

	# Set up referencing of Boost
	include_directories(${Boost_INCLUDE_DIR})

    # With 1-8 debian packages, there is a linker error with boost_system.
    # The solution were to add BOOST_SYSTEM_NO_DEPRECATED at compile: http://stackoverflow.com/a/30877725/2180332
	add_definitions(-DBOOST_ALL_NO_LIB -DBOOST_SYSTEM_NO_DEPRECATED)
	set(OGRE_LIBRARIES ${OGRE_LIBRARIES} ${Boost_LIBRARIES})
endif()

include_directories( ${OIS_INCLUDE_DIRS}
	${OGRE_INCLUDE_DIRS}
	${OGRE_SAMPLES_INCLUDEPATH}
	${OGRE_Overlay_INCLUDE_DIRS}
)

if (APPLE)
	add_executable(${APP} MACOSX_BUNDLE ${HDRS} ${SRCS})
elseif (WIN32)
	add_executable(${APP} WIN32 ${HDRS} ${SRCS})
else ()
	add_executable(${APP} ${HDRS} ${SRCS})
endif ()

set_target_properties(${APP} PROPERTIES DEBUG_POSTFIX _d)

target_link_libraries(${APP} ${OGRE_LIBRARIES} ${OIS_LIBRARIES} ${OGRE_Overlay_LIBRARIES})

if (APPLE)
		include_directories(
        ${OGRE_SDK}/include/OGRE/RenderSystems/GL/
        ${OGRE_SDK}/include/OGRE/RenderSystems/GL/OSX
    )

		set_source_files_properties(${CMAKE_SOURCE_DIR}/src/TutorialApplication.cpp PROPERTIES COMPILE_FLAGS "-x objective-c++")
		set_source_files_properties(${CMAKE_SOURCE_DIR}/src/BaseApplication.cpp PROPERTIES COMPILE_FLAGS "-x objective-c++")

		if (CMAKE_GENERATOR STREQUAL "Xcode")
			set (APP_CONTENTS_PATH ${CMAKE_CURRENT_BINARY_DIR}/dist/bin/$(CONFIGURATION)/${APP}.app/Contents)
		else ()
			set (APP_CONTENTS_PATH ${CMAKE_CURRENT_BINARY_DIR}/dist/bin/${APP}.app/Contents)
		endif ()

    set_target_properties(${APP} PROPERTIES
		LINK_FLAGS "-framework Foundation -framework Cocoa -framework OpenGL -framework CoreGraphics -framework IOKit -framework CoreVideo")

		set_property(TARGET ${APP} PROPERTY MACOSX_BUNDLE_ICON_FILE icon.icns)
		set_property(TARGET ${APP} PROPERTY MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/resources/Info.plist)
		set_property(TARGET ${APP} PROPERTY MACOSX_BUNDLE_GUI_IDENTIFIER "org.ogre3d.Clean")
    set_target_properties(${APP} PROPERTIES XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "NO")

		add_custom_command(TARGET ${APP} POST_BUILD
			COMMAND ditto ${CMAKE_SOURCE_DIR}/resources/icon.icns ${APP_CONTENTS_PATH}/Resources/
			COMMAND ditto ${CMAKE_SOURCE_DIR}/resources/resources.cfg ${APP_CONTENTS_PATH}/Resources/
			COMMAND ditto ${CMAKE_SOURCE_DIR}/resources/plugins.cfg ${APP_CONTENTS_PATH}/Resources/
			COMMAND ditto ${OGRE_SDK}/Media ${APP_CONTENTS_PATH}/Resources/Media
		)

		set(FRAMEWORKS
				Ogre
				OgreOverlay
        OgrePaging
        OgreProperty
        OgreRTShaderSystem
        OgreTerrain
        OgreVolume
        Plugin_BSPSceneManager
        Plugin_OctreeSceneManager
        Plugin_OctreeZone
        Plugin_ParticleFX
        Plugin_PCZSceneManager
        RenderSystem_GL
    )

    foreach(FWK ${FRAMEWORKS})
			add_custom_command(TARGET ${APP} POST_BUILD
				COMMAND ditto ${OGRE_SDK}/lib/RelWithDebInfo/${FWK}.framework ${APP_CONTENTS_PATH}/Frameworks/${FWK}.framework
			)
    endforeach(FWK)
endif ()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/dist/bin)
#file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/dist/media)

# post-build copy for win32
if(WIN32 AND NOT MINGW)
	add_custom_command( TARGET ${APP} PRE_BUILD
		COMMAND if not exist .\\dist\\bin mkdir .\\dist\\bin )
	add_custom_command( TARGET ${APP} POST_BUILD
		COMMAND copy \"$(TargetPath)\" .\\dist\\bin )
endif(WIN32 AND NOT MINGW)

if(MINGW OR UNIX)
	set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/dist/bin)
endif(MINGW OR UNIX)

if(WIN32)

	install(TARGETS ${APP}
		RUNTIME DESTINATION bin
		CONFIGURATIONS All)

	install(DIRECTORY ${CMAKE_SOURCE_DIR}/dist/Media
		DESTINATION ./
		CONFIGURATIONS Release RelWithDebInfo Debug
	)

	install(FILES ${CMAKE_SOURCE_DIR}/dist/bin/plugins.cfg
		${CMAKE_SOURCE_DIR}/dist/bin/resources.cfg
		DESTINATION bin
		CONFIGURATIONS Release RelWithDebInfo
	)

	install(FILES ${CMAKE_SOURCE_DIR}/dist/bin/plugins_d.cfg
		${CMAKE_SOURCE_DIR}/dist/bin/resources_d.cfg
		DESTINATION bin
		CONFIGURATIONS Debug
	)

        # NOTE: for the 1.7.1 sdk the OIS dll is called OIS.dll instead of libOIS.dll
        # so you'll have to change that to make it work with 1.7.1
	install(FILES ${OGRE_PLUGIN_DIR_REL}/OgreMain.dll
		${OGRE_PLUGIN_DIR_REL}/RenderSystem_Direct3D9.dll
		${OGRE_PLUGIN_DIR_REL}/RenderSystem_GL.dll
		${OGRE_PLUGIN_DIR_REL}/libOIS.dll
		DESTINATION bin
		CONFIGURATIONS Release RelWithDebInfo
	)

	install(FILES ${OGRE_PLUGIN_DIR_DBG}/OgreMain_d.dll
		${OGRE_PLUGIN_DIR_DBG}/RenderSystem_Direct3D9_d.dll
		${OGRE_PLUGIN_DIR_DBG}/RenderSystem_GL_d.dll
		${OGRE_PLUGIN_DIR_DBG}/libOIS_d.dll
		DESTINATION bin
		CONFIGURATIONS Debug
	)

   # as of sdk 1.7.2 we need to copy the boost dll's as well
   # because they're not linked statically (it worked with 1.7.1 though)
   install(FILES ${Boost_DATE_TIME_LIBRARY_RELEASE}
      ${Boost_THREAD_LIBRARY_RELEASE}
      DESTINATION bin
      CONFIGURATIONS Release RelWithDebInfo
   )

   install(FILES ${Boost_DATE_TIME_LIBRARY_DEBUG}
      ${Boost_THREAD_LIBRARY_DEBUG}
      DESTINATION bin
      CONFIGURATIONS Debug
   )
endif(WIN32)

if(UNIX)

	if(APPLE)
		install(TARGETS ${APP}
			BUNDLE DESTINATION bin
			CONFIGURATIONS All)
	else()
		install(TARGETS ${APP}
			RUNTIME DESTINATION bin
			CONFIGURATIONS All)
	endif(APPLE)

	install(DIRECTORY ${CMAKE_SOURCE_DIR}/dist/media
		DESTINATION ./
		CONFIGURATIONS Release RelWithDebInfo Debug
	)

	install(FILES ${CMAKE_SOURCE_DIR}/dist/bin/plugins.cfg
		${CMAKE_SOURCE_DIR}/dist/bin/resources.cfg
		DESTINATION bin
		CONFIGURATIONS Release RelWithDebInfo Debug
	)

endif(UNIX)
