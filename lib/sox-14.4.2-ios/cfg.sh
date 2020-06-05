#!/bin/sh
#export NDK=/Users/lerg/Library/Android/sdk/ndk-bundle
#$NDK/build/tools/make_standalone_toolchain.py --arch arm --api 28 --install-dir /Volumes/Extra/defold/arm_28_toolchain
#export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
# PREFIX="xcrun --sdk iphoneos -f"
# export CFLAGS="--arch arm"
# export CXXFLAGS=$CFLAGS
# export AR=`$PREFIX ar`
# export AS=`$PREFIX as`
# export CC=`$PREFIX gcc`
# export CXX=`$PREFIX g++`
# export LD=`$PREFIX ld`
# export RANLIB=`$PREFIX ranlib`
# export STRIP=`$PREFIX strip`
# ./configure --host arm-apple-darwin --target=arm-apple-darwin

OPT_FLAGS="-O3 -g3 -fPIC -ffunction-sections -funwind-tables -fstack-protector -march=arm64 -mfloat-abi=softfp -mfpu=vfpv3-d16 -fomit-frame-pointer -fstrict-aliasing -funswitch-loops -finline-limit=300"
MAKE_JOBS=8

dobuild() {
    export AR="$(xcrun --find --sdk "${SDK}" libtool) -o"
    export AS=$(xcrun --find --sdk "${SDK}" as)
    export CC=$(xcrun --find --sdk "${SDK}" gcc)
    export CXX=$(xcrun --find --sdk "${SDK}" g++)
    export CPP=$(xcrun --find --sdk "${SDK}" cpp)
    export LD=$(xcrun --find --sdk "${SDK}" ld)
    export RANLIB=$(xcrun --find --sdk "${SDK}" ranlib)
    export STRIP=$(xcrun --find --sdk "${SDK}" strip)
    export CFLAGS="${HOST_FLAGS} ${OPT_FLAGS}"
    export CXXFLAGS="${HOST_FLAGS} ${OPT_FLAGS}"
    export LDFLAGS="${HOST_FLAGS}"

    ./configure --host="${CHOST}" --enable-static

    make clean
    make -j"${MAKE_JOBS}"
}

SDK="iphoneos"
ARCH_FLAGS="-arch arm64"
HOST_FLAGS="${ARCH_FLAGS} -miphoneos-version-min=8.0 -isysroot $(xcrun --sdk ${SDK} --show-sdk-path)"
CHOST="arm-apple-darwin"
dobuild

libtool -static src/.libs/libsox_la-*.o libgsm/.libs/*.o lpc10/.libs/*.o -o libsox.a