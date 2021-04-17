#!/bin/bash
#
#  by dingfeng <dingfeng@qiniu.com>
#

ANDROID_NDK=/Users/lerg/ext/android-ndk-r18b
CMAKE=cmake

if [ -z "$ANDROID_NDK" ]; then
  echo "You must define ANDROID_NDK before starting."
  echo "They must point to your NDK directories.\n"
  exit 1
fi

if [ -z "$CMAKE" ]; then
  echo "You must define CMAKE before starting."
  exit 1
fi

# Detect OS
OS=`uname`
HOST_ARCH=`uname -m`
export CCACHE=; type ccache >/dev/null 2>&1 && export CCACHE=ccache
if [ $OS == 'Linux' ]; then
  export HOST_SYSTEM=linux-$HOST_ARCH
elif [ $OS == 'Darwin' ]; then
  export HOST_SYSTEM=darwin-$HOST_ARCH
fi

for arch in armeabi-v7a arm64-v8a; do
#for arch in armeabi-v7a; do

  case $arch in
    armeabi-v7a)
        SYSTEM_VERSION=28
        ANDROID_ARCH_ABI=armeabi-v7a
        SYSROOT=$ANDROID_NDK/platforms/android-$SYSTEM_VERSION/arch-arm
        C_COMPILER=arm-linux-androideabi-4.9/prebuilt/$HOST_SYSTEM/bin/arm-linux-androideabi
    ;;
    
    arm64-v8a)
        SYSTEM_VERSION=28
        ANDROID_ARCH_ABI=arm64-v8a
        SYSROOT=$ANDROID_NDK/platforms/android-$SYSTEM_VERSION/arch-arm64
        C_COMPILER=aarch64-linux-android-4.9/prebuilt/$HOST_SYSTEM/bin/aarch64-linux-android
        C_FLAGS=-DALIGNBYTES=7
    ;;
  esac

  mkdir -p tmplibs/$arch
  mkdir -p libs/$arch

  ${CMAKE} . \
    -DCMAKE_ANDROID_NDK=$ANDROID_NDK \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=$SYSTEM_VERSION \
    -DCMAKE_ANDROID_ARCH_ABI=$ANDROID_ARCH_ABI \
    -DCMAKE_C_COMPILER="$ANDROID_NDK/toolchains/$C_COMPILER-gcc" \
    -DCMAKE_C_FLAGS="-std=c99 -fopenmp -Os $C_FLAGS" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="../tmplibs/$arch"
    #-DCMAKE_C_FLAGS="-DHAVE_FMEMOPEN=TRUE -std=c99 -fopenmp $C_FLAGS"

  make all

  cp tmplibs/$arch/liblibsox.a libs/$arch
  cp tmplibs/$arch/libgsm.a libs/$arch
  cp tmplibs/$arch/liblpc10.a libs/$arch

  make clean
  rm -rf CMakeCache.txt CMakeFiles/
  rm -rf tmplibs/$arch

  echo "*****************************finish building arch $arch . *********************";

done