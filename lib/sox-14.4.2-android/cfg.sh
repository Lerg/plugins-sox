#!/bin/sh
#export NDK=/Users/lerg/Library/Android/sdk/ndk-bundle
#$NDK/build/tools/make_standalone_toolchain.py --arch arm --api 28 --install-dir /Volumes/Extra/defold/arm_28_toolchain
#export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
NDK=/Users/lerg/ext/android-ndk-r18b

ARCH=aarch64
#ARCH=arm

ARC=arm64
#ARC=arm

HOST=$ARCH-linux-android

export TOOLCHAIN=$NDK/toolchains/$ARCH-linux-android-4.9/prebuilt/darwin-x86_64

export AR=$TOOLCHAIN/bin/$HOST-ar
export AS=$TOOLCHAIN/bin/$HOST-as
export CC=$TOOLCHAIN/bin/$HOST-gcc
export CPP=$TOOLCHAIN/bin/$HOST-cpp
export CXX=$TOOLCHAIN/bin/$HOST-g++
export LD=$TOOLCHAIN/bin/$HOST-ld
export RANLIB=$TOOLCHAIN/bin/$HOST-ranlib
export STRIP=$TOOLCHAIN/bin/$HOST-strip
export CFLAGS="-fPIC -DANDROID -ffunction-sections -funwind-tables -fstack-protector -fomit-frame-pointer -fstrict-aliasing"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-DANDROID"

./configure --host $HOST