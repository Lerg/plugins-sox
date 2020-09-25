# Copyright (C) 2012 Corona Labs Inc.
#

# TARGET_PLATFORM := android-28

LOCAL_PATH := $(call my-dir)

CORONA_ENTERPRISE := /Applications/CoronaEnterprise
CORONA_ROOT := $(CORONA_ENTERPRISE)/Corona
LUA_API_DIR := $(CORONA_ROOT)/shared/include/lua
LUA_API_CORONA := $(CORONA_ROOT)/shared/include/Corona

PLUGIN_DIR := ../..

SRC_DIR := $(PLUGIN_DIR)/shared

# -----------------------------------------------------------------------------

include $(CLEAR_VARS)
LOCAL_MODULE := liblua
LOCAL_SRC_FILES := ../liblua.so
LOCAL_EXPORT_C_INCLUDES := $(LUA_API_DIR)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libcorona
LOCAL_SRC_FILES := ../libcorona.so
LOCAL_EXPORT_C_INCLUDES := $(LUA_API_CORONA)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    := libsox
LOCAL_SRC_FILES := libsox.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libgomp
LOCAL_SRC_FILES := /Users/lerg/ext/android-ndk-r10e/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/arm-linux-androideabi/lib/libgomp.a
include $(PREBUILT_STATIC_LIBRARY)
LOCAL_STATIC_LIBRARIES += libgomp

# -----------------------------------------------------------------------------

include $(CLEAR_VARS)
LOCAL_MODULE := libplugin.sox

LOCAL_C_INCLUDES := \
	$(SRC_DIR)

LOCAL_SRC_FILES := \
	$(SRC_DIR)/plugin_sox.cpp \
	$(SRC_DIR)/utils.cpp

LOCAL_CFLAGS := \
	-DANDROID_NDK \
	-DNDEBUG \
	-D_REENTRANT \
	-DRtt_ANDROID_ENV

LOCAL_LDLIBS := -llog -lgomp

LOCAL_SHARED_LIBRARIES := \
	liblua libcorona

LOCAL_STATIC_LIBRARIES := \
	libsox \
	libgomp

LOCAL_CFLAGS += -fopenmp
LOCAL_LDFLAGS += -fopenmp

ifeq ($(TARGET_ARCH),arm)
LOCAL_CFLAGS+= -D_ARM_ASSEM_
endif

# Arm vs Thumb.
LOCAL_ARM_MODE := arm
include $(BUILD_SHARED_LIBRARY)
