#!/usr/bin/bash
BINUTILS_VER=2.36.1
LLVM_VER=005a99c
WORKDIR=$PWD

echo "Cleaning build directory"
rm -rf build

mkdir -p build/binutils-$BINUTILS_VER
mkdir -p build/llvm-$LLVM_VER

echo "Downloading binutils-$BINUTILS_VER"
if ! [ -d binutils-$BINUTILS_VER ]; then
    wget -qO - https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.gz | tar xz
fi

echo "Configuring binutils-$BINUTILS_VER"
cd build/binutils-$BINUTILS_VER
../../binutils-$BINUTILS_VER/configure --target=z80-elf --program-prefix=z80-elf- --prefix=$WORKDIR/z80-elf

echo "Building binutils-$BINUTILS_VER"
make -j$(nproc)
make install

cd $WORKDIR

echo "Getting LLVM sources"
if ! [ -d llvm-project ]; then
    git clone --depth=1 https://github.com/jacobly0/llvm-project.git
    cd llvm-project
    git checkout $LLVM_VER
    patch -p1 < ../patch/0001-Emit-GAS-sytax.patch
    cd $WORKDIR
fi

echo "Building llvm-$LLVM_VER"
cmake -G Ninja -DLLVM_ENABLE_PROJECTS="clang" \
               -DCMAKE_INSTALL_PREFIX=$WORKDIR/z80-elf \
               -DCMAKE_BUILD_TYPE=Release \
               -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Z80 \
               -DLLVM_TARGETS_TO_BUILD= \
               -DLLVM_DEFAULT_TARGET_TRIPLE=z80-elf \
               -S llvm-project/llvm -B build/llvm-$LLVM_VER
cmake --build build/llvm-$LLVM_VER --target install
