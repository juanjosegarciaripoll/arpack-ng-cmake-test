#!/bin/sh
set -x
branch="cmake"
root=`pwd`
prefix=$root/local
python=no
branch=cmake
static=no
eigen=no
mpi=yes
examples=no
do_test=yes
do_build=yes
do_check=yes
cmake_generator="Unix Makefiles"
arpack_git="https://github.com/juanjosegarciaripoll/arpack-ng.git"
parallel=no

while [ -n "$1" ]; do
	case $1 in
		all)
			echo *** RUNNING STATICALLY LINKED TESTS
			if $0 clean static noeigen nopython check ; then
				echo *** SUCCESS
			else
				echo *** FAILURE
				exit 1
			fi
			echo *** RUNNING DYNAMICALLY LINKED TESTS
			if $0 clean shared noeigen nopython check ; then
				echo *** SUCCESS
			else
				echo *** FAILURE
				exit 1
			fi
			;;
		new|cmake)
			branch=cmake
			shift;;
		master)
			branch=master
			shift;;
		clean)
			rm -rf build/{arpack-ng,cmake-test,boost*} cmake-test/*.{c,cpp,log} makedir-test/*.{c,cpp,log}
			rm -rf $prefix/lib/libarpack* $prefix/include/arpack-ng $prefix/lib/cmake/arpack* $prefix/lib/pkgconfig/*arpack*
			shift;;
		static)
			static=yes
			shift;;
		dynamic|shared)
			static=no
			shift;;
		check)
			do_check=yes
			shift;;
		nocheck)
			do_check=no
			shift;;
		eigen)
			eigen=yes
			shift;;
		noeigen)
			eigen=no
			shift;;
		examples)
			examples=yes
			shift;;
		noexamples)
			examples=no
			shift;;
		mpi)
			mpi=yes
			shift;;
		nompi)
			mpi=no
			shift;;
		nopython)
			python=no
			shift;;
		python)
			python=yes
			shift;;
		build)
			do_build=yes
			shift;;
		nobuild)
			do_build=no
			shift;;
		parallel)
			shift
			if [ "$1" -eq "$1" ]; then
				parallel=$1
				shift
			fi;;
		test)
			do_test=yes
			shift;;
		notest)
			do_test=no
			shift;;
		*)
			echo Uknown option $1
			exit 1;;
	esac
done

if [ $do_check = yes ]; then
	ARPACK_CTEST="ctest --output-on-failure"
else
	ARPACK_CTEST="echo No test"
fi
if [ $parallel != no ]; then
	ARPACK_CMAKE_JOBS="-j $parallel"
fi
if [ $static = yes ]; then
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DBUILD_SHARED_LIBS=OFF"
else
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DBUILD_SHARED_LIBS=ON"
fi
if [ $examples = yes ]; then
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DEXAMPLES=ON"
else
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DEXAMPLES=OFF"
fi
if [ $mpi = yes ]; then
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DMPI=ON"
else
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DMPI=OFF"
fi
if [ $eigen = yes ]; then
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DICBEXMM=ON"
else
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DICBEXMM=OFF"
fi
arpack=arpack-ng-$branch
arpack_build=`pwd`/build/$arpack
arpack_source=`pwd`/source/$arpack

if [ ! -d $arpack_source ]; then
	test -d source || mkdir source
	if (git clone $arpack_git $arpack_source && \
		cd $arpack_source && \
		git checkout -b $branch --track origin/$branch); then
		echo Checked out repository
	else
		echo Failure checking out repository
		exit 1
	fi
fi

if [ $python = no ]; then
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DPYTHON3=OFF"
else
	ARPACK_CMAKE_FLAGS="$ARPACK_CMAKE_FLAGS -DPYTHON3=ON"
	if [ ! -d $prefix/include/boost* ]; then
		# This is needed to link to python on Debian
		if [ "x" = "y" ] ; then
			sudo apt-get update
			sudo apt-get install -y gfortran gcc g++ openmpi-bin libopenmpi-dev libopenblas-dev liblapack-dev cmake libeigen3-dev
			sudo apt-get -y install python3-minimal python3-pip python3-numpy
			sudo apt-get -y install wget
		fi
		if [ ! -d $prefix/include/boost ]; then
			if (cd build &&
					wget https://sourceforge.net/projects/boost/files/boost/1.79.0/boost_1_79_0.tar.gz && \
						tar -xf boost_1_79_0.tar.gz && \
						(cd boost_1_79_0 && \
							 ./bootstrap.sh --with-libraries=python --with-python=/usr/bin/python3 --with-toolset=gcc && \
							 ./b2 toolset=gcc --prefix=$prefix install) && \
						rm -rf boost_1_79_0); then
				echo Succeeded installing Boost
			else
				echo Failed installing Boost
				rm -rf build/boost_1_79*
				exit 1
			fi
		fi
	fi
fi

if [ $do_build = yes ]; then
	if (rm -rf "$arpack_build" && \
			mkdir -p "$arpack_build" && \
			cd "$arpack_build" && \
			cmake -S "$arpack_source" -B . -DCMAKE_INSTALL_PREFIX="$prefix"\
 				  -G "$cmake_generator" -DICB=ON -DICBEXMM=ON \
				  $ARPACK_CMAKE_FLAGS && \
			cmake --build . $ARPACK_CMAKE_JOBS && \
			cmake --install . && $ARPACK_CTEST $ARPACK_CMAKE_JOBS) 2>&1; then
		echo Succeeded building Arpack-NG
	else
		echo Failure building Arpack-NG sources
		exit 1
	fi
fi

if [ $do_test = yes ]; then
	test_build=`pwd`/build/cmake-test
	for file in icb_arpack_c.c icb_arpack_cpp.cpp; do
		#cat "$arpack_source/TESTS/$file" | sed -e 's,#include ",#include "arpack-ng/,g' > cmake-test/$file
		cp "$arpack_source/TESTS/$file" "cmake-test/$file"
	done
	if (rm -rf "$test_build" && \
			mkdir -p "$test_build" && \
			cmake -S cmake-test -B "$test_build" -G "$cmake_generator" \
				  -D CMAKE_PREFIX_PATH="$prefix" $ARPACK_TEST_CMAKE_FLAGS && \
			cmake --build "$test_build" --verbose) 2>&1; then
		echo Succeeded building tests
	else
		echo Failure building tests
		exit 1
	fi
	if $test_build/icb_arpack_c 2>&1 >"$test_build/icb_arpack_c.log"; then
		echo Succeeded icb_arpack_c
	else
		echo Failed icb_arpack_c
		exit 1
	fi
	if $test_build/icb_arpack_cpp 2>&1 >"$test_build/icb_arpack_cpp.log"; then
		echo Succeeded icb_arpack_cpp
	else
		echo Failed icb_arpack_cpp
		exit 1
	fi
fi
