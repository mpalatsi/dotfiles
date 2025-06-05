#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                    Pulsing Border Effect Script            ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Pulsing border colors with different intensities
PULSE_BRIGHT="rgba(7B4E7Fff) rgba(82524Aff) 45deg"
PULSE_MEDIUM="rgba(7B4E7FDD) rgba(82524ADD) 45deg"
PULSE_DIM="rgba(7B4E7FBB) rgba(82524ABB) 45deg"
PULSE_SOFT="rgba(7B4E7F99) rgba(82524A99) 45deg"

# Pulse timing (in seconds)
PULSE_SPEED=1.5

# Function to set border color
set_border_color() {
    hyprctl keyword general:col.active_border "$1" >/dev/null 2>&1
}

# Function for smooth pulsing cycle
pulse_cycle() {
    # Bright phase
    set_border_color "$PULSE_BRIGHT"
    sleep $PULSE_SPEED
    
    # Medium phase
    set_border_color "$PULSE_MEDIUM"
    sleep $PULSE_SPEED
    
    # Dim phase
    set_border_color "$PULSE_DIM"
    sleep $PULSE_SPEED
    
    # Soft phase
    set_border_color "$PULSE_SOFT"
    sleep $PULSE_SPEED
    
    # Back to medium
    set_border_color "$PULSE_MEDIUM"
    sleep $PULSE_SPEED
}

# Cleanup function
cleanup() {
    echo "Stopping border pulsing..."
    set_border_color "$PULSE_BRIGHT"
    exit 0
}

# Trap signals for clean exit
trap cleanup SIGINT SIGTERM

echo "Starting border pulsing effect..."
echo "Press Ctrl+C to stop"

# Main pulsing loop
while true; do
    pulse_cycle
done 