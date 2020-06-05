#!/bin/sh
#
# Checks exit value for error
# 
checkError() {
    if [ $? -ne 0 ]
    then
        echo "Exiting due to errors (above)"
        exit -1
    fi
}

PLUGINS_DIR="${HOME}/Library/Application Support/Corona/Simulator/Plugins"

mkdir -p "$PLUGINS_DIR"
checkError

cp -v $CONFIGURATION_BUILD_DIR/$FULL_PRODUCT_NAME "$PLUGINS_DIR"/.
checkError

