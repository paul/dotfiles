#!/usr/bin/env zsh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

PRIMARY_MONITOR=$(xrandr | grep " connected primary" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
SECONDARY_MONITOR=$(xrandr | grep " connected" | grep -v "primary" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")

export MONITOR=$PRIMARY_MONITOR
polybar primary &

if [[ -v SECONDARY_MONITOR ]]; then
  export MONITOR=$SECONDARY_MONITOR
  polybar secondary &
fi

unset MONITOR

