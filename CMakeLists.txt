#/*
#-----------------------------------------------------------------------------
#Filename:    CMakeLists.txt
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
cmake_minimum_required(VERSION 2.6)

set(APP "OgreApp")

set(HDRS
	./src/BaseApplication.h
	./src/TutorialApplication.h
  ./src/AppDelegate.h
)

set(SRCS
	./src/BaseApplication.cpp
	./src/TutorialApplication.cpp
  ./src/AppDelegate.mm
)

include("tools/cmake/common.cmake")
