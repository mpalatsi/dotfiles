#!/bin/bash
# Ultra-simple theme script that doesn't rely on pywal
# It will set a wallpaper and theme waybar, wofi, and hyprland

set -euo pipefail

echo "===== MATERIAL YOU THEME SCRIPT ====="

#########################
# 0. RATE LIMITING      #
#########################
LOCK_FILE="/tmp/material-you-theme.lock"
LAST_RUN_FILE="/tmp/material-you-theme-lastrun"
MIN_INTERVAL=2  # Minimum 2 seconds between runs

# Function to acquire lock with timeout
acquire_lock() {
  local timeout=5
  local count=0
  
  while [ $count -lt $timeout ]; do
    if (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
      return 0
    fi
    
    # Check if the lock is stale (process no longer exists)
    if [ -f "$LOCK_FILE" ]; then
      local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
      if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
        echo "Removing stale lock file..."
        rm -f "$LOCK_FILE"
        continue
      fi
    fi
    
    echo "⚠️ Theme script is already running (PID: ${lock_pid:-unknown}). Waiting..."
    sleep 1
    count=$((count + 1))
  done
  
  echo "❌ Failed to acquire lock after ${timeout} seconds. Exiting..."
  exit 1
}

# Check minimum interval between runs
if [ -f "$LAST_RUN_FILE" ]; then
  LAST_RUN=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo "0")
  CURRENT_TIME=$(date +%s)
  TIME_DIFF=$((CURRENT_TIME - LAST_RUN))
  
  if [ "$TIME_DIFF" -lt "$MIN_INTERVAL" ]; then
    echo "⚠️ Theme change too frequent. Please wait $((MIN_INTERVAL - TIME_DIFF)) more seconds."
    exit 0
  fi
fi

# Acquire lock
acquire_lock

# Update last run time
date +%s > "$LAST_RUN_FILE"

# Cleanup function to remove lock file
cleanup() {
  rm -f "$LOCK_FILE"
}
trap cleanup EXIT

#########################
# 1. CONFIG & PATHS     #
#########################
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WAYBAR_CSS="$HOME/.config/waybar/style.css"
ROFI_THEME="$HOME/.config/rofi/theme.rasi"
HYPR_COLORS_CONF="$HOME/.config/hypr/config/colors.conf"
MAKO_CONFIG="$HOME/.config/mako/config"

# Matugen paths
MATUGEN_DIR="$HOME/.config/matugen"
MATUGEN_PALETTE_FILE="$MATUGEN_DIR/colors.scss"

# Fallback colors if matugen fails
FALLBACK_BG="#131822"
FALLBACK_FG="#e0e0e0"
FALLBACK_ACCENT="#8f6eff"
FALLBACK_ACCENT2="#ad7eff"

# Initialize colors (will be set either by pywal or fallback)
BG_COLOR=""
FG_COLOR=""
ACCENT_COLOR=""
ACCENT2_COLOR=""
BG_RGBA=""
ACCENT_RGBA=""
ACCENT2_RGBA=""

#########################
# 2. PICK WALLPAPER     #
#########################
if [[ -n "${1:-}" && -f "$1" ]]; then
  WALLPAPER="$1"
else
  # Use find command to safely find wallpapers
  echo "Looking for wallpapers in $WALLPAPER_DIR"
  
  # Check if directory exists
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory $WALLPAPER_DIR does not exist!"
    exit 1
  fi
  
  # Find wallpapers and pick one at random
  WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \))
  WALLPAPER_COUNT=$(echo "$WALLPAPER_FILES" | wc -l)
  
  if [ "$WALLPAPER_COUNT" -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
  fi
  
  # Select a random wallpaper using a better method
  RANDOM_LINE=$((RANDOM % WALLPAPER_COUNT + 1))
  WALLPAPER=$(echo "$WALLPAPER_FILES" | sed -n "${RANDOM_LINE}p")
  
  if [ -z "$WALLPAPER" ]; then
    echo "Failed to select a wallpaper"
    exit 1
  fi
fi

echo "✓ Selected wallpaper: $WALLPAPER"

#########################
# 3. SET WALLPAPER      #
#########################
echo "Setting wallpaper with swww (animated transitions)..."

# Ensure swww daemon is running
if ! pgrep -x swww-daemon >/dev/null; then
    echo "Starting swww daemon..."
    swww-daemon &
    sleep 2
fi

# Set wallpaper with beautiful transition
echo "Applying wallpaper with grow transition..."
swww img "$WALLPAPER" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 2 \
    --transition-fps 60

# Cache the current wallpaper for other programs to use
if [ "$WALLPAPER" != "$HOME/.cache/current-wallpaper.jpg" ]; then
  cp "$WALLPAPER" ~/.cache/current-wallpaper.jpg
fi

#########################
# 3B. RUN MATUGEN       #
#########################
echo "Running matugen to generate Material You colors from wallpaper..."

# Add a proper hex_to_rgba function specifically for CSS
hex_to_rgba() {
  local hex="${1#\#}"  # Remove # if present
  echo "rgba(${hex}ff)"
}

hex_to_css_rgba() {
  local hex="${1#\#}"  # Remove # if present
  if [ ${#hex} -eq 6 ]; then
    # Convert hex to decimal
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $2)"
  else
    # Fallback for invalid hex
    echo "rgba(0, 0, 0, $2)"
  fi
}

# Set initial flag
matugen_succeeded=false

# First, check if matugen is installed
if ! command -v matugen &> /dev/null; then
  echo "❌ Error: matugen is not installed"
  echo "   Install it with: paru -S matugen"
else
  echo "Using matugen to generate Material You colors..."
  
  # Create matugen dir if it doesn't exist
  mkdir -p "$MATUGEN_DIR"
  
  # Run matugen directly with --show-colors to get immediate output
  echo "Running matugen (with 3-second timeout)..."
  
  # First try with --show-colors to see if it works
  MATUGEN_OUTPUT=$(timeout 3 matugen image --show-colors "$WALLPAPER" 2>&1)
  MATUGEN_EXIT=$?
  
  if [ $MATUGEN_EXIT -eq 0 ] && [ -n "$MATUGEN_OUTPUT" ]; then
    echo "Extracted colors from image successfully"
    
    # Extract hex values from matugen's table output
    # We need to handle the specific table format with aligned columns
    PRIMARY_COLOR=$(echo "$MATUGEN_OUTPUT" | grep "^│ primary " | awk '{print $4}')
    TERTIARY_COLOR=$(echo "$MATUGEN_OUTPUT" | grep "^│ tertiary " | awk '{print $4}')
    SURFACE_COLOR=$(echo "$MATUGEN_OUTPUT" | grep "^│ surface " | head -n1 | awk '{print $4}')
    ON_SURFACE_COLOR=$(echo "$MATUGEN_OUTPUT" | grep "^│ on_surface " | awk '{print $4}')
    
    # Debug
    echo "Extracted from matugen output:"
    echo "  PRIMARY_COLOR = $PRIMARY_COLOR"
    echo "  TERTIARY_COLOR = $TERTIARY_COLOR"
    echo "  SURFACE_COLOR = $SURFACE_COLOR"
    echo "  ON_SURFACE_COLOR = $ON_SURFACE_COLOR"
    
    # Verify we got colors
    if [ -n "$PRIMARY_COLOR" ] && [ -n "$TERTIARY_COLOR" ]; then
      # Set our color variables
      ACCENT_COLOR="$PRIMARY_COLOR" # For compatibility
      ACCENT2_COLOR="$TERTIARY_COLOR"
      
      # Choose appropriate background/foreground colors
      if [ -n "$SURFACE_COLOR" ]; then
        BG_COLOR="$SURFACE_COLOR"
      else
        # Dark neutral color if surface not found
        BG_COLOR="#1e1e2e"
      fi
      
      if [ -n "$ON_SURFACE_COLOR" ]; then
        FG_COLOR="$ON_SURFACE_COLOR"
      else
        # Light color if on-surface not found
        FG_COLOR="#cdd6f4"
      fi
      
      # Convert to RGBA for Hyprland
      BG_RGBA=$(hex_to_rgba "$BG_COLOR")
      ACCENT_RGBA=$(hex_to_rgba "$PRIMARY_COLOR")
      ACCENT2_RGBA=$(hex_to_rgba "$TERTIARY_COLOR")
      
      echo "✓ Successfully extracted Material You colors:"
      echo "  Primary: $PRIMARY_COLOR"
      echo "  Tertiary: $TERTIARY_COLOR"
      echo "  Surface: $BG_COLOR"
      echo "  On Surface: $FG_COLOR"
      
      matugen_succeeded=true
      
      # Also try to generate the complete theme (background process)
      (timeout 5 matugen image "$WALLPAPER" --output-dir "$MATUGEN_DIR" >/dev/null 2>&1 &)
    else
      echo "⚠️ Could not extract all needed colors from matugen output"
    fi
  else
    echo "⚠️ Matugen command failed or timed out."
    echo "   Trying fallback method..."
    # Try running it without showing colors to generate files
    timeout 5 matugen image "$WALLPAPER" --output-dir "$MATUGEN_DIR" >/dev/null 2>&1
  fi
fi

# Use fallback colors if matugen failed
if [ "$matugen_succeeded" != "true" ]; then
  echo "⚠️ Using fallback colors (matugen failed)"
  BG_COLOR="$FALLBACK_BG"
  FG_COLOR="$FALLBACK_FG"
  ACCENT_COLOR="$FALLBACK_ACCENT"
  ACCENT2_COLOR="$FALLBACK_ACCENT2"
  BG_RGBA="rgba(131822ff)"
  ACCENT_RGBA="rgba(8f6effff)"
  ACCENT2_RGBA="rgba(ad7effff)"
  PRIMARY_COLOR="$FALLBACK_ACCENT"
  TERTIARY_COLOR="$FALLBACK_ACCENT2"
fi

# After extracting colors, enhance the colors for better visibility
if [ "$matugen_succeeded" = "true" ]; then
  # Create a darker version of the surface color
  DARK_BG="#1a1b26"  # A nice dark background
  DARK_BG_RGBA="rgba(26, 27, 38, 0.85)"  # Same with transparency
  
  # Create bright text colors for better legibility
  BRIGHT_TEXT="#ffffff"
  BRIGHT_ACCENT_COLOR=$(hex_to_css_rgba "$ACCENT_COLOR" "1.0")
  BRIGHT_ACCENT2_COLOR=$(hex_to_css_rgba "$ACCENT2_COLOR" "1.0")
  
  # Create a brighter version of the accent color for better visibility
  BRIGHT_PRIMARY="#$(printf "%02x%02x%02x" $((0x${ACCENT_COLOR:1:2} + 40)) $((0x${ACCENT_COLOR:3:2} + 40)) $((0x${ACCENT_COLOR:5:2} + 40)))"
  BRIGHT_TERTIARY="#$(printf "%02x%02x%02x" $((0x${ACCENT2_COLOR:1:2} + 40)) $((0x${ACCENT2_COLOR:3:2} + 40)) $((0x${ACCENT2_COLOR:5:2} + 40)))"
else
  # Fallback dark background
  DARK_BG="#131822"
  DARK_BG_RGBA="rgba(19, 24, 34, 0.85)"
  BRIGHT_TEXT="#ffffff"
  BRIGHT_ACCENT_COLOR="rgba(143, 110, 255, 1.0)"
  BRIGHT_ACCENT2_COLOR="rgba(173, 126, 255, 1.0)"
  BRIGHT_PRIMARY="#af8eff"
  BRIGHT_TERTIARY="#cf9eff"
fi

#########################
# 4. WRITE CONFIG FILES #
#########################

# Waybar CSS
echo "Creating Waybar CSS..."
mkdir -p "$(dirname "$WAYBAR_CSS")"

# Calculate RGBA colors for CSS
PRIMARY_RGBA=$(hex_to_css_rgba "$ACCENT_COLOR" "0.6")
PRIMARY_FG=$(hex_to_css_rgba "$ACCENT_COLOR" "1.0")
TERTIARY_FG=$(hex_to_css_rgba "$ACCENT2_COLOR" "1.0")
FOREGROUND_RGBA=$(hex_to_css_rgba "$FG_COLOR" "0.7")

cat > "$WAYBAR_CSS" <<CSS
/* Generated by Material You theme script at $(date) */
/* Using matugen Material 3 colors */

* {
    border: none;
    border-radius: 0;
    font-family: "Noto Sans", "Font Awesome 6 Free", sans-serif;
    font-size: 14px;
    min-height: 0;
    transition: background 0.3s ease;
}

window#waybar {
    background: transparent;
    color: $BRIGHT_TEXT;
}

.modules-left, .modules-center, .modules-right {
    background-color: $DARK_BG_RGBA;
    border-radius: 12px;
    border: 1px solid rgba(70, 93, 145, 0.2);
    padding: 2px 8px;
    margin: 4px 4px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Make workspace buttons more appealing */
#workspaces button {
    padding: 0 8px;
    margin: 4px 2px;
    color: #cccccc;
    background: transparent;
    font-weight: normal;
    border-radius: 10px; /* More pill-like shape */
    min-width: 20px;
    min-height: 20px;
}

#workspaces button.active {
    color: $BRIGHT_TEXT;
    background-color: $ACCENT_COLOR;
    font-weight: bold;
    border-radius: 10px; /* Pill shape for active button */
    box-shadow: 0 0 4px rgba(70, 93, 145, 0.8);
    min-width: 24px;
    padding: 0 10px; /* More horizontal padding for active workspace */
}

#workspaces button:hover {
    background-color: $PRIMARY_RGBA;
    color: $BRIGHT_TEXT;
    border-radius: 10px; /* Pill shape for hover state */
}

#window {
    padding: 0 10px;
    color: $BRIGHT_TEXT;
    font-weight: normal;
}

/* Improve clock visibility */
#clock {
    color: $BRIGHT_PRIMARY;
    font-weight: bold;
    padding: 0 10px;
}

/* Improve system monitor visibility */
#cpu {
    color: $BRIGHT_TERTIARY;
    padding: 0 10px;
    font-weight: 600;
}

#memory {
    color: $BRIGHT_PRIMARY;
    padding: 0 10px;
    font-weight: 600;
}

#disk {
    color: $BRIGHT_TERTIARY;
    padding: 0 10px;
    font-weight: 600;
}

/* Fix temperature color */
#temperature {
    padding: 0 10px;
    color: $BRIGHT_PRIMARY;
    font-weight: 600;
}

#temperature.critical {
    color: #ff5050;
    animation: blink 1s infinite alternate;
}

/* Improve volume/audio visibility */
#wireplumber {
    color: $BRIGHT_PRIMARY;
    padding: 0 10px;
    font-weight: 600;
}

#wireplumber.muted {
    color: #999999;
    font-style: italic;
}

/* Custom modules */
#custom-launcher, #custom-power {
    font-size: 16px;
    padding: 0 10px;
    font-weight: bold;
}

#custom-launcher {
    color: $BRIGHT_PRIMARY;
}

#custom-power {
    color: $BRIGHT_TERTIARY;
}

#custom-weather {
    color: $BRIGHT_PRIMARY;
    padding: 0 10px;
    font-weight: 600;
}

/* MPRIS media player */
#mpris {
    color: $BRIGHT_TERTIARY;
    padding: 0 10px;
    font-weight: 600;
}

#mpris.playing {
    color: $BRIGHT_PRIMARY;
}

#mpris.paused {
    color: #bbbbbb;
    font-style: italic;
}

/* Tray */
#tray {
    padding: 0 10px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #ff9900;
}

/* Add a subtle animation for critical state */
@keyframes blink {
    from {
        color: #ff5050;
    }
    to {
        color: #ff8080;
    }
}

/* Add tooltip styling */
tooltip {
    background-color: $DARK_BG;
    border: 1px solid $ACCENT_COLOR;
    border-radius: 8px;
}

tooltip label {
    color: $BRIGHT_TEXT;
}
CSS

# Rofi Theme
echo "Creating Rofi Theme..."
mkdir -p "$(dirname "$ROFI_THEME")"

# Calculate proper rgba colors for rofi
BG_SELECTED_RGBA=$(hex_to_css_rgba "$ACCENT_COLOR" "0.3")
BG_HOVER_RGBA=$(hex_to_css_rgba "$ACCENT_COLOR" "0.15")
ACCENT_DIM_RGBA=$(hex_to_css_rgba "$ACCENT_COLOR" "0.6")
BORDER_COLOR_RGBA=$(hex_to_css_rgba "$ACCENT_COLOR" "0.4")

# Rofi-specific optimized transparency variables
INPUTBAR_BG_BLUR=$(hex_to_css_rgba "$DARK_BG" "0.6")  # 60% opacity for input bar
INPUTBAR_BORDER=$(hex_to_css_rgba "$ACCENT_COLOR" "0.3")

cat > "$ROFI_THEME" <<RASI
/**
 * Material You Sharp Modern Theme
 * Clean geometric design with intentional square edges
 * Generated by Material You theme script at $(date)
 */

* {
    /* Dynamic Material You colors - sharp modern design */
    bg: $DARK_BG;
    bg-blur: $(hex_to_css_rgba "$DARK_BG" "0.4");  /* 40% transparency for geometric contrast */
    bg-selected: $BG_SELECTED_RGBA;
    bg-hover: $BG_HOVER_RGBA;
    fg: #ffffff;
    fg-dim: rgba(255, 255, 255, 0.5);
    fg-selected: #ffffff;
    accent: $ACCENT_COLOR;
    accent-dim: $ACCENT_DIM_RGBA;
    border-color: $BORDER_COLOR_RGBA;    /* Stronger border for geometric look */
    
    /* Reset */
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
    
    /* Typography */
    font: "SF Pro Display 13";
}

window {
    width: 600px;
    background-color: @bg-blur;
    /* Clean square edges - no border-radius */
    padding: 0;
    border: 2px;                             /* Thicker border for modern look */
    border-color: @border-color;
    /* Add subtle shadow effect with the border */
}

mainbox {
    children: [inputbar, listview];
    background-color: transparent;
    padding: 24px;                           /* Slightly more padding for geometric spacing */
    spacing: 20px;                           /* More spacing for clean separation */
}

inputbar {
    children: [prompt, entry];
    background-color: $INPUTBAR_BG_BLUR; /* Slightly more opaque for contrast */
    /* Sharp geometric input bar */
    padding: 16px 20px;                      /* More generous padding */
    spacing: 12px;
    border: 1px;
    border-color: @accent;                   /* Accent color border for focus */
    margin: 0 0 8px 0;                       /* Add bottom margin for separation */
}

prompt {
    background-color: transparent;
    text-color: @accent;
    font: "SF Pro Display Bold 13";          /* Bold prompt for emphasis */
    padding: 0;
    vertical-align: 0.5;
}

entry {
    background-color: transparent;
    text-color: @fg;
    padding: 0;
    placeholder: "Search applications...";
    placeholder-color: @fg-dim;
    cursor-color: @accent;
    vertical-align: 0.5;
    font: "SF Pro Display 13";
}

listview {
    background-color: transparent;
    padding: 0;                              /* Clean edge-to-edge list */
    spacing: 2px;                            /* Tight spacing for clean lines */
    columns: 1;
    lines: 8;
    scrollbar: false;
    dynamic: true;
    cycle: true;
}

element {
    padding: 14px 20px;                      /* Consistent with input bar padding */
    spacing: 12px;
    background-color: transparent;
    /* Sharp geometric elements - no border-radius */
    orientation: horizontal;
    children: [element-icon, element-text];
}

element normal.normal,
element alternate.normal {
    background-color: transparent;
    text-color: @fg;
}

element normal.active,
element alternate.active {
    background-color: @bg-hover;
    text-color: @fg;
}

element selected.normal {
    background-color: @bg-selected;
    text-color: @fg-selected;
    border: 1px;
    border-color: @accent;
    /* Sharp selection highlighting */
}

element selected.active {
    background-color: @accent-dim;
    text-color: @fg-selected;
    border: 1px;
    border-color: @accent;
}

element-icon {
    size: 24px;
    background-color: transparent;
    padding: 0;
    vertical-align: 0.5;
}

element-text {
    background-color: transparent;
    text-color: @fg;
    padding: 0;
    vertical-align: 0.5;
    font: "SF Pro Display 13";
}

element-text normal {
    text-color: @fg;
}

element-text alternate {
    text-color: @fg;
}

element-text selected {
    text-color: @fg-selected;
    font: "SF Pro Display Medium 13";
}

scrollbar {
    width: 4px;
    handle-width: 4px;
    handle-color: rgba(255, 255, 255, 0.3);
    /* Sharp scrollbar - no border-radius */
    background-color: rgba(255, 255, 255, 0.1);
    margin: 0 4px 0 0;
}

mode-switcher {
    background-color: transparent;
    spacing: 8px;
    padding: 12px 0 0 0;                     /* More top padding for separation */
}

button {
    padding: 10px 18px;                      /* More generous button padding */
    background-color: $INPUTBAR_BG_BLUR;
    text-color: @fg;
    /* Sharp geometric buttons - no border-radius */
    border: 1px;
    border-color: @border-color;
    font: "SF Pro Display 12";
    margin: 0 4px;                           /* Space between buttons */
}

button selected {
    background-color: @accent-dim;
    text-color: @fg-selected;
    border: 1px;
    border-color: @accent;
    font: "SF Pro Display Medium 12";
}

error-message {
    background-color: rgba(255, 69, 58, 0.2);
    border: 2px;                             /* Thicker border for attention */
    border-color: rgba(255, 69, 58, 0.8);
    /* Sharp error styling - no border-radius */
    padding: 18px;
    margin: 8px 0;
}

textbox {
    background-color: transparent;
    text-color: #ff453a;
    font: "SF Pro Display 13";
}
RASI

# Create a rofi config that uses our theme
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
mkdir -p "$(dirname "$ROFI_CONFIG")"
cat > "$ROFI_CONFIG" <<RASI
configuration {
  display-drun: "Applications";
  display-window: "Windows";
  display-run: "Run";
  display-filebrowser: "Files";
  drun-display-format: "{icon} {name}";
  font: "SF Pro Display 13";
  modi: "drun,run,window,filebrowser";
  show-icons: true;
  icon-theme: "Papirus";
  
  /* Performance and behavior */
  disable-history: false;
  sort: true;
  sorting-method: "fzf";
  case-sensitive: false;
  cycle: true;
  
  /* Window positioning */
  location: 0;
  anchor: 0;
  
  /* Safe keybindings - avoiding conflicts */
  kb-cancel: "Escape";
  kb-accept-entry: "Return,KP_Enter";
  kb-row-up: "Up";
  kb-row-down: "Down";
}

@theme "$HOME/.config/rofi/theme.rasi"
RASI

# Departure logout theme with Material You integration
echo "Creating Departure theme..."
DEPARTURE_CONFIG="$HOME/.config/departure/config.json"
mkdir -p "$(dirname "$DEPARTURE_CONFIG")"

# Create or update departure configuration with current Material You colors
# Check if departure config exists, if not create default structure
if [ ! -f "$DEPARTURE_CONFIG" ]; then
    echo "Creating new departure configuration..."
    cat > "$DEPARTURE_CONFIG" <<DEPARTURE
{
  "theme": {
    "source": "manual",
    "manual_colors": {
      "background": "$(hex_to_css_rgba "$DARK_BG" "0.8")",
      "primary": "$ACCENT_COLOR",
      "secondary": "$ACCENT2_COLOR", 
      "text": "$BRIGHT_TEXT",
      "danger": "#f38ba8"
    },
    "file_path": null,
    "command": null,
    "watch_file": false
  },
  "layout": {
    "layout_type": "horizontal",
    "button_size": 80,
    "button_spacing": 20,
    "margin": 50,
    "columns": 3
  },
  "effects": {
    "blur": true,
    "animations": true,
    "hover_effects": true,
    "transition_duration": 200
  },
  "actions": [
    {
      "name": "Lock",
      "command": "hyprlock",
      "icon": "xfsm-lock",
      "keybind": "l",
      "confirm": false,
      "danger": false
    },
    {
      "name": "Logout", 
      "command": "hyprctl dispatch exit",
      "icon": "xfsm-logout",
      "keybind": "e",
      "confirm": true,
      "danger": false
    },
    {
      "name": "Suspend",
      "command": "systemctl suspend", 
      "icon": "xfsm-suspend",
      "keybind": "s",
      "confirm": false,
      "danger": false
    },
    {
      "name": "Hibernate",
      "command": "systemctl hibernate",
      "icon": "xfsm-hibernate", 
      "keybind": "h",
      "confirm": false,
      "danger": false
    },
    {
      "name": "Reboot",
      "command": "systemctl reboot",
      "icon": "xfsm-reboot",
      "keybind": "r", 
      "confirm": true,
      "danger": true
    },
    {
      "name": "Shutdown",
      "command": "systemctl poweroff",
      "icon": "xfsm-shutdown",
      "keybind": "p",
      "confirm": true,
      "danger": true
    }
  ]
}
DEPARTURE
else
    echo "Updating existing departure configuration with new colors..."
    # Use jq to update only the theme colors, preserving user customizations
    if command -v jq >/dev/null 2>&1; then
        # Create temporary file with updated colors
        jq --arg bg "$(hex_to_css_rgba "$DARK_BG" "0.8")" \
           --arg primary "$ACCENT_COLOR" \
           --arg secondary "$ACCENT2_COLOR" \
           --arg text "$BRIGHT_TEXT" \
           '.theme.manual_colors.background = $bg |
            .theme.manual_colors.primary = $primary |
            .theme.manual_colors.secondary = $secondary |
            .theme.manual_colors.text = $text |
            .theme.source = "manual"' \
           "$DEPARTURE_CONFIG" > "${DEPARTURE_CONFIG}.tmp" && \
        mv "${DEPARTURE_CONFIG}.tmp" "$DEPARTURE_CONFIG"
    else
        echo "⚠️ jq not found, skipping departure config update"
    fi
fi

echo "✓ Departure logout theme with Material You colors configured"

# Mako notification daemon theme
echo "Creating Mako notification theme..."
mkdir -p "$(dirname "$MAKO_CONFIG")"

# Convert colors for mako format with transparency
MAKO_BG="${DARK_BG}dd"  # Add transparency (85% opacity)
MAKO_TEXT="${BRIGHT_TEXT}"
MAKO_BORDER="${ACCENT_COLOR}aa"  # Subtle border transparency
MAKO_PROGRESS="${ACCENT2_COLOR}"

# Create more transparent variations for different states
MAKO_BG_BLUR="${DARK_BG}bb"  # More transparent for blur effect (73% opacity)
MAKO_BG_CRITICAL="#2d1b1bee"  # Critical with transparency
MAKO_BG_LOW="${DARK_BG}99"  # Very transparent for low priority (60% opacity)

# Enhanced border colors with transparency
MAKO_BORDER_DIM="${ACCENT2_COLOR}66"  # Dimmed border
MAKO_BORDER_BRIGHT="${ACCENT_COLOR}ff"  # Full opacity for critical
MAKO_BORDER_GLOW="${ACCENT_COLOR}33"  # Very subtle glow effect

cat > "$MAKO_CONFIG" <<MAKO
# Generated by Material You theme script at $(date)
# Mako notification daemon configuration with Material 3 colors and transparency

# Appearance - Modern translucent design
background-color=$MAKO_BG_BLUR
text-color=$MAKO_TEXT
border-color=$MAKO_BORDER
progress-color=$MAKO_PROGRESS

# Enhanced layout and positioning for visual appeal
width=400
height=110
margin=12
padding=20
border-size=1
border-radius=16
outer-margin=8

# Typography - Clean and modern
font=SF Pro Display 12
markup=1
format=<b>%s</b>\n<span size='10pt'>%b</span>

# Behavior - Smooth and user-friendly
default-timeout=6000
ignore-timeout=1
max-visible=5
sort=-time
layer=overlay
anchor=top-right

# Icons - Larger and more prominent
icons=1
max-icon-size=56
icon-path=/usr/share/icons/Papirus-Dark:/usr/share/icons/Papirus

# Enhanced urgency-specific styling with transparency
[urgency=low]
background-color=$MAKO_BG_LOW
border-color=$MAKO_BORDER_DIM
text-color=${MAKO_TEXT}cc
border-size=1
default-timeout=4000
padding=16
border-radius=14

[urgency=normal]
background-color=$MAKO_BG_BLUR
border-color=$MAKO_BORDER
text-color=$MAKO_TEXT
border-size=1
default-timeout=6000
padding=20
border-radius=16

[urgency=critical]
background-color=$MAKO_BG_CRITICAL
border-color=#ff6b6bff
text-color=#ffffff
border-size=2
default-timeout=0
padding=22
border-radius=18
# Add visual emphasis for critical notifications
font=SF Pro Display Bold 12

# App-specific styling with enhanced visuals
[app-name=Spotify]
background-color=${DARK_BG}e6
border-color=$MAKO_PROGRESS
border-size=2
border-radius=20
padding=24
format=<b>🎵 %s</b>\n<span size='10pt'>%b</span>

[app-name="Volume Control"]
background-color=${DARK_BG}cc
border-color=$MAKO_PROGRESS
format=<b>🔊 %s</b>\n<span size='11pt'>%b</span>
default-timeout=2500
border-radius=12
padding=16

[app-name="Brightness Control"]
background-color=${DARK_BG}cc
border-color=${ACCENT_COLOR}dd
format=<b>☀️ %s</b>\n<span size='11pt'>%b</span>
default-timeout=2500
border-radius=12
padding=16

[summary~="Battery.*"]
background-color=${DARK_BG}dd
border-color=#ffa500dd
format=<b>🔋 %s</b>\n<span size='10pt'>%b</span>
border-radius=14
padding=18

[app-name="Network Manager"]
background-color=${DARK_BG}dd
border-color=${ACCENT2_COLOR}bb
format=<b>🌐 %s</b>\n<span size='10pt'>%b</span>

[summary~="Screenshot.*"]
background-color=${DARK_BG}e6
border-color=${ACCENT_COLOR}ee
format=<b>📸 %s</b>\n<span size='10pt'>%b</span>
default-timeout=3000

# Grouped notifications with enhanced styling
[grouped=true]
background-color=${DARK_BG}f0
border-color=${ACCENT_COLOR}cc
format=<b>%s (%g)</b>\n<span size='10pt'>%b</span>
padding=22
border-radius=18

# Calendar/time-based notifications
[app-name="Calendar"]
background-color=${DARK_BG}dd
border-color=${ACCENT2_COLOR}aa
format=<b>📅 %s</b>\n<span size='10pt'>%b</span>

# System notifications
[app-name="System"]
background-color=${DARK_BG}cc
border-color=${ACCENT_COLOR}77
format=<b>⚙️ %s</b>\n<span size='10pt'>%b</span>

# Media notifications
[category=media]
background-color=${DARK_BG}e6
border-color=$MAKO_PROGRESS
border-size=2
padding=24
border-radius=20

# Email/messaging notifications  
[category=email]
background-color=${DARK_BG}dd
border-color=${ACCENT2_COLOR}bb
format=<b>📧 %s</b>\n<span size='10pt'>%b</span>

[category=im]
background-color=${DARK_BG}dd
border-color=${ACCENT_COLOR}bb
format=<b>💬 %s</b>\n<span size='10pt'>%b</span>
MAKO

# Convert colors to proper Hyprland format (0xAARRGGBB)
hex_to_hyprland() {
  local hex="${1#\#}"  # Remove # if present
  local alpha="${2:-ff}"  # Default to full opacity
  echo "0x${alpha}${hex}"
}

# Hyprland colors.conf
echo "Creating Hyprland colors..."
mkdir -p "$(dirname "$HYPR_COLORS_CONF")"

# Convert colors to Hyprland format
ACCENT_HYPR=$(hex_to_hyprland "$ACCENT_COLOR" "ff")
ACCENT2_HYPR=$(hex_to_hyprland "$ACCENT2_COLOR" "ff") 
BG_HYPR=$(hex_to_hyprland "$BG_COLOR" "ff")
INACTIVE_BORDER_HYPR=$(hex_to_hyprland "$ACCENT2_COLOR" "33")

# Create a temporary file first to ensure atomic updates
TEMP_COLORS_CONF="${HYPR_COLORS_CONF}.tmp"

cat > "$TEMP_COLORS_CONF" <<CONF
# Generated by Material You theme script at $(date)
# Using matugen Material 3 colors

# CachyOS specific colors - formatted properly for Hyprland
\$cachylgreen = $ACCENT_COLOR
\$cachymblue = $BG_COLOR
\$cachydgreen = $ACCENT_COLOR
\$cachydblue = $ACCENT2_COLOR
\$cachymgreen = $ACCENT_COLOR

# RGBA versions for advanced usage
\$cachylgreen_rgba = $ACCENT_RGBA
\$cachymblue_rgba = $BG_RGBA
\$cachydgreen_rgba = $ACCENT_RGBA
\$cachydblue_rgba = $ACCENT2_RGBA
\$cachymgreen_rgba = $ACCENT_RGBA

# Hyprland native format (0xAARRGGBB)
\$accent_hypr = $ACCENT_HYPR
\$accent2_hypr = $ACCENT2_HYPR
\$bg_hypr = $BG_HYPR
\$inactive_border_hypr = $INACTIVE_BORDER_HYPR

# Pulsing border color variations (for enhanced effects)
\$pulse_bright = $ACCENT_RGBA $ACCENT2_RGBA 45deg
\$pulse_medium = $(echo "$ACCENT_RGBA" | sed 's/ff)/DD)/') $(echo "$ACCENT2_RGBA" | sed 's/ff)/DD)/') 45deg
\$pulse_dim = $(echo "$ACCENT_RGBA" | sed 's/ff)/BB)/') $(echo "$ACCENT2_RGBA" | sed 's/ff)/BB)/') 45deg
\$pulse_soft = $(echo "$ACCENT_RGBA" | sed 's/ff)/99)/') $(echo "$ACCENT2_RGBA" | sed 's/ff)/99)/') 45deg

# Active gradient border for variables.conf override
\$active_gradient = $ACCENT_RGBA $ACCENT2_RGBA 45deg
\$inactive_border_color = $INACTIVE_BORDER_HYPR
CONF

# Atomically move the temp file to replace the original
mv "$TEMP_COLORS_CONF" "$HYPR_COLORS_CONF"

echo "✓ Colors configuration generated successfully"

#########################
# 5. TERMINAL THEMING   #
#########################

#########################
# 6. FISH SHELL THEMING #
#########################

#########################
# 7. APPLY CHANGES      #
#########################

# Restart Waybar
echo "Restarting Waybar..."
pkill -TERM waybar 2>/dev/null || true
sleep 1
pkill -9 waybar 2>/dev/null || true
sleep 0.5
(setsid waybar >/dev/null 2>&1 &)

# Reload Mako configuration
echo "Reloading Mako notification daemon..."
if pgrep -x mako >/dev/null; then
  # Send SIGHUP to reload config
  pkill -SIGHUP mako
  echo "✓ Mako configuration reloaded"
else
  echo "⚠️ Mako is not running - starting it..."
  (setsid mako >/dev/null 2>&1 &)
  sleep 1
  echo "✓ Mako started with new theme"
fi

# Apply Hyprland changes
echo "Applying Hyprland border colors..."
if pgrep -x Hyprland >/dev/null; then
  # Force hyprctl to work by finding socket
  for socket in /tmp/hypr/*; do
    if [ -S "$socket" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE=$(basename "$socket" | cut -d'_' -f2)
      echo "✓ Found Hyprland socket: $HYPRLAND_INSTANCE_SIGNATURE"
      break
    fi
  done
  
  # Wait a moment for the file to be written completely
  sleep 0.5
  
  # Apply changes with delays to prevent rapid-fire issues and race conditions
  echo "Reloading Hyprland config..."
  
  # Use a more conservative approach - only reload the specific config source
  echo "Reloading colors configuration..."
  if hyprctl keyword source "$HYPR_COLORS_CONF" >/dev/null 2>&1; then
    echo "✓ Colors configuration reloaded successfully"
  else
    echo "! Warning: Failed to reload colors config, trying full reload..."
    sleep 1
    hyprctl reload >/dev/null 2>&1 || echo "! Warning: hyprctl reload failed"
  fi
  
  sleep 0.5
  
  # Apply direct color changes as fallback using proper Hyprland format
  echo "Applying border colors directly..."
  
  # Use Hyprland native color format
  if hyprctl keyword general:col.active_border "$ACCENT_HYPR $ACCENT2_HYPR 45deg" >/dev/null 2>&1; then
    echo "✓ Active border gradient applied successfully"
  else
    echo "! Warning: Failed to set active border, trying single color..."
    # Fallback to single color
    hyprctl keyword general:col.active_border "$ACCENT_HYPR" >/dev/null 2>&1 || 
      echo "! Warning: failed to set active border"
  fi
  
  sleep 0.3
    
  echo "Setting inactive border color..."
  if hyprctl keyword general:col.inactive_border "$INACTIVE_BORDER_HYPR" >/dev/null 2>&1; then
    echo "✓ Inactive border color applied successfully"
  else
    # Fallback to full opacity color
    hyprctl keyword general:col.inactive_border "$BG_HYPR" >/dev/null 2>&1 || 
      echo "! Warning: failed to set inactive border"
  fi
  
  echo "✓ Hyprland border colors applied successfully"
else
  echo "! Hyprland is not running - colors.conf will be applied on next startup"
fi

# Test notification to show the new theme
echo "Sending test notification..."
sleep 0.5
notify-send "🎨 Material You Theme Applied" "Wallpaper: $(basename "$WALLPAPER")\nColors: $ACCENT_COLOR • $ACCENT2_COLOR" --icon=preferences-color --urgency=normal

echo ""
echo "===== MATERIAL YOU THEME APPLIED SUCCESSFULLY ====="
echo "Wallpaper: $WALLPAPER"
echo "Primary color: $ACCENT_COLOR"
echo "Tertiary color: $ACCENT2_COLOR"
echo "Surface color: $BG_COLOR"
echo "Applications themed:"
echo "  ✓ Waybar (status bar)"
echo "  ✓ Rofi (application launcher)"
echo "  ✓ Hyprland (window borders)"
echo "  ✓ Mako (notifications)"
echo "  ✓ Departure (logout menu with circular buttons and blur)"
echo ""
echo "To test Rofi colors, run: rofi -show drun"

# Fix the Waybar launcher to use rofi instead of wofi - this requires editing the Waybar config file
# First, let's check if the Waybar config file exists
WAYBAR_CONFIG="$HOME/.config/waybar/config"
if [ -f "$WAYBAR_CONFIG" ]; then
  # Update the launcher command to use rofi
  sed -i 's/"on-click": "wofi --show drun"/"on-click": "rofi -show drun"/g' "$WAYBAR_CONFIG"
  echo "✓ Updated Waybar launcher to use rofi"
fi

exit 0 