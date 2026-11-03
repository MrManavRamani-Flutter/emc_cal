#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
RELEASE_APP="$DIR/build/macos/Build/Products/Release/OM MAVTAR GROUP.app"
DEBUG_APP="$DIR/build/macos/Build/Products/Debug/OM MAVTAR GROUP.app"

if [ -d "$RELEASE_APP" ]; then
    echo "Starting OM MAVTAR GROUP Desktop App..."
    open "$RELEASE_APP"
elif [ -d "$DEBUG_APP" ]; then
    echo "Starting OM MAVTAR GROUP Desktop App..."
    open "$DEBUG_APP"
else
    echo "Build not found. Building and running..."
    cd "$DIR"
    flutter run -d macos
fi
