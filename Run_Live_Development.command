#!/bin/bash
# -------------------------------------------------------------
# OM MAVTAR GROUP — Live Development Runner (with Hot-Reload)
# -------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PATH="/Users/manavramani/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$DIR" || exit 1

python3 "$DIR/scripts/live_runner.py"
