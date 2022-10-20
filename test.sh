#!/bin/sh
set -x
branch="cmake"
prefix=`pwd`/local
which=new
static=no
cmake_generator="Unix Makefiles"

while [ -n "$1" ]; do
	case $1 in
		new)
			which=new
			shift;;
		original)
			which=original
			shift;;
		clean)
			rm -rf build/* cmake-test/*.{c,cpp,log} makedir-test/*.{c,cpp,log}
			rm -rf $prefix/lib/libarpack* $prefix/include/arpack-ng $prefix/lib/cmake/arpack* $prefix/lib/pkgconfig/*arpack*
			shift;;
		static)
			static=yes
			shift;;
		dynamic)
			static=no
			shift;;
		*)
			echo Uknown option $1
			exit -1;;
	esac
done

case "$which" in
	new)
		arpack="arpack-ng"
		branch=cmake
		;;
	original)
		arpack="arpack-ng-original"
		branch=master
		;;
	*)
		echo Do not know which branch to test: "$which"
		exit -1
esac
if [ $static = yes ]; then
	ARPACK_CMAKE_FLAGS=-DBUILD_SHARED_LIBS=OFF
else
	ARPACK_CMAKE_FLAGS=-DBUILD_SHARED_LIBS=ON
fi
arpack_build=`pwd`/build/$arpack
arpack_source=`pwd`/source/$arpack

if [ ! -d $arpack_source ]; then
	test -d source || mkdir source
	git clone https://github.com/juanjosegarciaripoll/arpack-ng.git $arpack_source
	git checkout --track origin/$branch
fi

if [ ! -d $prefix/include/boost* ]; then
	# This is needed to link to python on Debian
	if [ "x" = "y" ] ; then
		sudo apt-get update
		sudo apt-get install -y gfortran gcc g++ openmpi-bin libopenmpi-dev libblas-dev liblapack-dev cmake libeigen3-dev
		sudo apt-get -y install python3-minimal python3-pip python3-numpy
		sudo apt-get -y install wget
	fi
	if [ ! -d $prefix/include/boost ]; then
		cd build &&
		wget https://sourceforge.net/projects/boost/files/boost/1.79.0/boost_1_79_0.tar.gz && \
		tar -xf boost_1_79_0.tar.gz && \
		(cd boost_1_79_0 && \
		./bootstrap.sh --with-libraries=python --with-python=/usr/bin/python3 --with-toolset=gcc && \
		./b2 toolset=gcc --prefix=$prefix install) && \
		rm -rf boost_1_79_0
	fi
fi

if (rm -rf $arpack_build && \
		mkdir -p $arpack_build && \
		cd $arpack_build && \
		cmake -S $arpack_source -B . -DCMAKE_INSTALL_PREFIX="$prefix"\
 			  -G "$cmake_generator" -DICB=ON -DICBEXMM=ON -DPYTHON3=ON \
			  $ARPACK_CMAKE_FLAGS && \
		cmake --build . -j 6 && \
		cmake --install .); then
	echo Succeeded building Arpack-NG
else
	echo Failure building Arpack-NG sources
	exit -1
fi

test_build=`pwd`/build/cmake-test
if (cp $arpack_source/TESTS/icb_arpack_c.c cmake-test/ && \
		cp $arpack_source/TESTS/icb_arpack_cpp.cpp cmake-test/ && \
		rm -rf $test_build && \
		mkdir -p $test_build && \
		cmake -S cmake-test -B $test_build -G "$cmake_generator" \
			  -D CMAKE_PREFIX_PATH="$prefix" && \
		cmake --build $test_build --verbose); then
	echo Succeeded building tests
else
	echo Failure building tests
	exit -1
fi
if $test_build/icb_arpack_c 2>&1 >$test_build/icb_arpack_c.log; then
	echo Succeeded icb_arpack_c
else
	echo Failed icb_arpack_c
	exit -1
fi
if $test_build/icb_arpack_cpp 2>&1 >$test_build/icb_arpack_cpp.log; then
	echo Succeeded icb_arpack_cpp
else
	echo Failed icb_arpack_cpp
	exit -1
fi
