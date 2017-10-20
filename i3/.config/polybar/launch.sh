#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

PRIMARY_MONITOR=$(xrandr | grep -E " connected (primary )?[1-9]+" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
SECONDARY_MONITOR=$(xrandr | grep -E " connected ^(primary )?[1-9]+" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")

MONITOR=$PRIMARY_MONITOR polybar primary &

if [ -z ${SECONDARY_MONITOR+x} ]; then
  MONITOR=$SECONDARY_MONITOR polybar secondary &
fi

