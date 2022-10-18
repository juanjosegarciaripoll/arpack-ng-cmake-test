#!/bin/sh
branch="cmake"
prefix=`pwd`/local
rm -rf build build-arpack local build-cmake-test
if [ ! -d $prefix/lib ]; then
	if [ ! -d arpack-ng ]; then
		git clone https://github.com/juanjosegarciaripoll/arpack-ng.git
		git checkout --track origin/$branch
	fi
	rm -rf build-arpack
	mkdir build-arpack
	cmake -S ./arpack-ng -B build-arpack -D CMAKE_INSTALL_PREFIX="$prefix" -D ICB=ON -D ICBEXM=ON -D MPI=ON
	cmake --build build-arpack
	cmake --install build-arpack
fi
cp arpack-ng/TESTS/icb_arpack_c.c cmake-test/icb_arpack_c.c
cp arpack-ng/TESTS/icb_arpack_cpp.cpp cmake-test/icb_arpack_cpp.cpp
rm -rf build-cmake-test
cmake -S cmake-test -B build-cmake-test -G "Unix Makefiles" -D CMAKE_PREFIX_PATH="$prefix"
cmake --build build-cmake-test
if ./build-cmake-test/icb_arpack_c 2>&1 >build-cmake-test/icb_arpack_c.log; then
	echo Succeeded icb_arpack_c
else
	echo Failed icb_arpack_c
	exit -1
fi
if ./build-cmake-test/icb_arpack_cpp 2>&1 >build-cmake-test/icb_arpack_cpp.log; then
	echo Succeeded icb_arpack_cpp
else
	echo Failed icb_arpack_cpp
	exit -1
fi
