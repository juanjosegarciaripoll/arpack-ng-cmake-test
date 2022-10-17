#!/bin/sh
branch="cmake"
prefix=`pwd`/local
if [ ! -d arpack-ng ]; then
	git clone https://github.com/juanjosegarciaripoll/arpack-ng.git
	git checkout --track origin/$branch
fi
rm -rf build
mkdir build
if [ ! -f arpack-ng/Makefile.in ]; then
	(cd ./arpack-ng && ./bootstrap)
fi
cd build
../arpack-ng/configure --prefix=$prefix --enable-icb --enable-icb-exmm --enable-mpi
make -j4
make -j4 install
