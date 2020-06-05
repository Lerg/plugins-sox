#!/bin/sh
#export NDK=/Users/lerg/Library/Android/sdk/ndk-bundle
#$NDK/build/tools/make_standalone_toolchain.py --arch arm --api 28 --install-dir /Volumes/Extra/defold/arm_28_toolchain
#export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
HOST=arm-linux-androideabi
NDK=/Volumes/Extra/corona/engine/android-ndk-r10d
export TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
export AR=$TOOLCHAIN/bin/$HOST-ar
export AS=$TOOLCHAIN/bin/$HOST-as
export CC=$TOOLCHAIN/bin/$HOST-gcc
export CPP=$TOOLCHAIN/bin/$HOST-cpp
export CXX=$TOOLCHAIN/bin/$HOST-g++
export LD=$TOOLCHAIN/bin/$HOST-ld
export RANLIB=$TOOLCHAIN/bin/$HOST-ranlib
export STRIP=$TOOLCHAIN/bin/$HOST-strip
export CFLAGS="-fPIC --sysroot=$NDK/platforms/android-21/arch-arm/ -DANDROID -ffunction-sections -funwind-tables -fstack-protector -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fomit-frame-pointer -fstrict-aliasing -funswitch-loops -finline-limit=300"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="--sysroot=$NDK/platforms/android-21/arch-arm/ -DANDROID"
./configure --host $HOST