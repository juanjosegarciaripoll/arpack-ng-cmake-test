cmake_minimum_required(VERSION 3.18)

# set the project name and version
project(test-arpack-cmake
  VERSION 0.1
  DESCRIPTION "Test using ARPACK libraries with CMake")

#set(CMAKE_FIND_DEBUG_MODE TRUE)

find_package(arpackng)

add_executable(icb_arpack_c icb_arpack_c.c)
target_link_libraries(icb_arpack_c PUBLIC ARPACK::ARPACK)

add_executable(icb_arpack_cpp icb_arpack_cpp.cpp)
target_link_libraries(icb_arpack_cpp PUBLIC ARPACK::ARPACK)
