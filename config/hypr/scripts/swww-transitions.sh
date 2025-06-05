#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃                    SWWW Transition Demo Script             ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Function to get a random wallpaper
get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) | shuf -n 1
}

# Function to set wallpaper with specific transition
set_wallpaper_transition() {
    local transition_type="$1"
    local wallpaper=$(get_random_wallpaper)
    
    echo "🎨 Setting wallpaper with $transition_type transition..."
    echo "📁 Wallpaper: $(basename "$wallpaper")"
    
    case "$transition_type" in
        "fade")
            swww img "$wallpaper" \
                --transition-type fade \
                --transition-duration 2 \
                --transition-fps 60
            ;;
        "slide")
            swww img "$wallpaper" \
                --transition-type slide \
                --transition-angle 45 \
                --transition-duration 1.5 \
                --transition-fps 60
            ;;
        "grow")
            swww img "$wallpaper" \
                --transition-type grow \
                --transition-pos 0.5,0.5 \
                --transition-duration 2 \
                --transition-fps 60
            ;;
        "wave")
            swww img "$wallpaper" \
                --transition-type wave \
                --transition-angle 30 \
                --transition-duration 2 \
                --transition-fps 60
            ;;
        "wipe")
            swww img "$wallpaper" \
                --transition-type wipe \
                --transition-angle 90 \
                --transition-duration 1.5 \
                --transition-fps 60
            ;;
        *)
            echo "❌ Unknown transition type: $transition_type"
            echo "Available: fade, slide, grow, wave, wipe"
            return 1
            ;;
    esac
    
    echo "✅ Transition complete!"
}

# Main menu
if [ $# -eq 0 ]; then
    echo "🌟 SWWW Transition Demo"
    echo "======================"
    echo "Usage: $0 [transition_type]"
    echo ""
    echo "Available transitions:"
    echo "  fade  - Smooth fade transition (default)"
    echo "  slide - Slide from angle"
    echo "  grow  - Growing circle effect"
    echo "  wave  - Wave effect"
    echo "  wipe  - Wipe transition"
    echo ""
    echo "Example: $0 wave"
    exit 0
fi

# Check if swww daemon is running
if ! pgrep -x swww-daemon >/dev/null; then
    echo "🚀 Starting swww daemon..."
    swww-daemon &
    sleep 2
fi

# Set wallpaper with specified transition
set_wallpaper_transition "$1" 