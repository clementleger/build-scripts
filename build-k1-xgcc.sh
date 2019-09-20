#!/usr/bin/env bash
set -eu

DOWNLOAD_REQ=1

## Set these for using specific revision
SHA1_GCC=3130e1ac4928043ca6572804065955a900795c67
SHA1_GDB=fe938e201ac54619a188fa92959bf0c41eff10f5
SHA1_NEWLIB=bfac2db4903b666c4595ccfa74e5f4c8af685873

TARGET=k1-elf
PREFIX=$(realpath $1)

PARALLEL_JOBS=-j6


mkdir -p $PREFIX
export PATH=$PREFIX/bin:$PATH

git clone --depth 1 -b coolidge https://github.com/kalray/gdb-binutils.git
if [[ ! -z "$SHA1_GDB" ]]
then
   cd gdb-binutils
   git reset --hard $SHA1_GDB
   cd -
fi

git clone --depth 1 -b coolidge https://github.com/kalray/newlib.git
if [[ ! -z "$SHA1_NEWLIB" ]]
then
   cd newlib
   git reset --hard $SHA1_NEWLIB
   cd -
fi

git clone --depth 1 -b coolidge https://github.com/kalray/gcc.git
if [[ ! -z "$SHA1_GCC" ]]
then
   cd gcc
   git reset --hard $SHA1_GCC
   cd -
fi

mkdir build-binutils
cd build-binutils
../gdb-binutils/configure --prefix=$PREFIX --target=$TARGET --disable-initfini-array  --disable-gdb --without-gdb --disable-werror   --with-expat=yes --with-babeltrace=no --with-bugurl=no
make all $PARALLEL_JOBS
make install

cd -
cd gcc

./contrib/download_prerequisites

cd -
mkdir build-gcc
cd build-gcc
../gcc/configure --prefix=$PREFIX --target=$TARGET  --with-gnu-as --with-gnu-ld --disable-bootstrap --disable-shared --enable-multilib --disable-libmudflap --disable-libssp --enable-__cxa_atexit --with-bugurl=no --with-newlib                      --disable-libgomp --disable-libatomic --disable-threads --enable-languages=c --with-system-zlib

make all-gcc $PARALLEL_JOBS
make install-gcc

cd -
mkdir build-newlib
cd  build-newlib
../newlib/configure --target=$TARGET --prefix=$PREFIX \
            --enable-multilib \
            --enable-target-optspace \
            --enable-newlib-io-c99-formats \
            --target=${TARGET} \
	    --enable-newlib-multithread

make all $PARALLEL_JOBS
make install

cd -
cd build-gcc
make all $PARALLEL_JOBS
make install

echo "Finished"
