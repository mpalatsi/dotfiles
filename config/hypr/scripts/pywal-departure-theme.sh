#!/bin/bash
# Enhanced Material You theme script with Departure integration
# Themes waybar, rofi, hyprland, mako, and departure with Material You colors

set -euo pipefail

echo "===== MATERIAL YOU + DEPARTURE THEME SCRIPT ====="

#########################
# 1. CONFIG & PATHS     #
#########################
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WAYBAR_CSS="$HOME/.config/waybar/style.css"
ROFI_THEME="$HOME/.config/rofi/theme.rasi"
HYPR_COLORS_CONF="$HOME/.config/hypr/config/colors.conf"
MAKO_CONFIG="$HOME/.config/mako/config"
DEPARTURE_CONFIG="$HOME/.config/departure/config.json"

# Matugen paths
MATUGEN_DIR="$HOME/.config/matugen"
MATUGEN_COLORS_JSON="$MATUGEN_DIR/colors.json"

#########################
# 2. UTILITY FUNCTIONS  #
#########################

hex_to_rgb() {
    local hex="$1"
    hex="${hex#"#"}"
    printf "%d, %d, %d" 0x"${hex:0:2}" 0x"${hex:2:2}" 0x"${hex:4:2}"
}

hex_to_css_rgba() {
    local hex="$1"
    local alpha="${2:-1.0}"
    local rgb=$(hex_to_rgb "$hex")
    echo "rgba($rgb, $alpha)"
}

#########################
# 3. SET WALLPAPER      #
#########################

if [ $# -eq 0 ]; then
    # No wallpaper specified, pick a random one
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)
    echo "Selected random wallpaper: $WALLPAPER"
else
    WALLPAPER="$1"
    echo "Using specified wallpaper: $WALLPAPER"
fi

# Set wallpaper
echo "Setting wallpaper..."
swww img "$WALLPAPER" --transition-type wipe --transition-duration 2 || {
    echo "Failed to set wallpaper with swww, trying hyprctl..."
    hyprctl hyprpaper wallpaper ",$WALLPAPER"
}

#########################
# 4. GENERATE COLORS    #
#########################

echo "Generating Material You colors with matugen..."

# Create matugen directory if it doesn't exist
mkdir -p "$MATUGEN_DIR"

# Generate colors with matugen
if command -v matugen >/dev/null 2>&1; then
    matugen image "$WALLPAPER" -j json > "$MATUGEN_COLORS_JSON" 2>/dev/null || {
        echo "Warning: matugen failed, using fallback colors"
        # Create a basic color scheme as fallback
        cat > "$MATUGEN_COLORS_JSON" <<EOF
{
  "colors": {
    "primary": {"hex": "#8f6eff"},
    "secondary": {"hex": "#7c4dff"},
    "tertiary": {"hex": "#ad7eff"},
    "surface": {"hex": "#131822"},
    "on_surface": {"hex": "#e0e0e0"},
    "error": {"hex": "#f28b82"}
  }
}
EOF
    }
else
    echo "Warning: matugen not found, using fallback colors"
    cat > "$MATUGEN_COLORS_JSON" <<EOF
{
  "colors": {
    "primary": {"hex": "#8f6eff"},
    "secondary": {"hex": "#7c4dff"},
    "tertiary": {"hex": "#ad7eff"},
    "surface": {"hex": "#131822"},
    "on_surface": {"hex": "#e0e0e0"},
    "error": {"hex": "#f28b82"}
  }
}
EOF
fi

# Extract colors from generated JSON
PRIMARY=$(jq -r '.colors.primary.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#8f6eff")
SECONDARY=$(jq -r '.colors.secondary.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#7c4dff")
TERTIARY=$(jq -r '.colors.tertiary.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#ad7eff")
SURFACE=$(jq -r '.colors.surface.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#131822")
ON_SURFACE=$(jq -r '.colors.on_surface.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#e0e0e0")
ERROR=$(jq -r '.colors.error.hex' "$MATUGEN_COLORS_JSON" 2>/dev/null || echo "#f28b82")

echo "Generated colors:"
echo "  Primary: $PRIMARY"
echo "  Secondary: $SECONDARY"
echo "  Tertiary: $TERTIARY"
echo "  Surface: $SURFACE"
echo "  Text: $ON_SURFACE"
echo "  Error: $ERROR"

#########################
# 5. UPDATE DEPARTURE   #
#########################

echo "Updating Departure configuration..."

# Update departure config to use file-based theming
if [ -f "$DEPARTURE_CONFIG" ]; then
    # Create a temporary departure config that watches the matugen file
    jq --arg json_path "$MATUGEN_COLORS_JSON" '
    .theme.source = "file" |
    .theme.file_path = $json_path |
    .theme.watch_file = true
    ' "$DEPARTURE_CONFIG" > "${DEPARTURE_CONFIG}.tmp" && mv "${DEPARTURE_CONFIG}.tmp" "$DEPARTURE_CONFIG"
    
    echo "✓ Updated Departure to use matugen colors"
else
    echo "Warning: Departure config not found. Run 'departure --generate-config' first."
fi

#########################
# 6. UPDATE OTHER APPS  #
#########################

echo "Updating Waybar..."
# Update waybar CSS (simplified version)
cat > "$WAYBAR_CSS" <<EOF
/* Material You Theme - Generated $(date) */
@define-color primary $PRIMARY;
@define-color secondary $SECONDARY;
@define-color tertiary $TERTIARY;
@define-color surface $SURFACE;
@define-color on-surface $ON_SURFACE;
@define-color error $ERROR;

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background-color: $(hex_to_css_rgba "$SURFACE" "0.9");
    border-bottom: 3px solid $PRIMARY;
    color: $ON_SURFACE;
}

.modules-left, .modules-center, .modules-right {
    background-color: transparent;
}

#workspaces button {
    padding: 0 10px;
    background-color: transparent;
    color: $(hex_to_css_rgba "$ON_SURFACE" "0.7");
    border-bottom: 3px solid transparent;
}

#workspaces button:hover {
    background-color: $(hex_to_css_rgba "$PRIMARY" "0.2");
    color: $ON_SURFACE;
}

#workspaces button.active {
    background-color: $(hex_to_css_rgba "$PRIMARY" "0.3");
    color: $ON_SURFACE;
    border-bottom: 3px solid $PRIMARY;
}

#clock, #battery, #cpu, #memory, #disk, #temperature, #network, #pulseaudio {
    padding: 0 10px;
    color: $ON_SURFACE;
}

#battery.critical:not(.charging) {
    background-color: $ERROR;
    color: $SURFACE;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
EOF

echo "Updating Rofi..."
# Update rofi theme
mkdir -p "$(dirname "$ROFI_THEME")"
cat > "$ROFI_THEME" <<EOF
/* Material You Theme - Generated $(date) */
* {
    primary: $PRIMARY;
    secondary: $SECONDARY;
    tertiary: $TERTIARY;
    surface: $SURFACE;
    on-surface: $ON_SURFACE;
    error: $ERROR;
    
    background-color: transparent;
    text-color: @on-surface;
}

window {
    background-color: $(hex_to_css_rgba "$SURFACE" "0.95");
    border: 2px solid @primary;
    border-radius: 10px;
    padding: 15px;
}

inputbar {
    background-color: $(hex_to_css_rgba "$PRIMARY" "0.2");
    border-radius: 5px;
    padding: 8px;
    margin: 0 0 10px 0;
}

listview {
    background-color: transparent;
    spacing: 2px;
}

element {
    background-color: transparent;
    padding: 8px;
    border-radius: 5px;
}

element selected {
    background-color: $(hex_to_css_rgba "$PRIMARY" "0.3");
    color: @on-surface;
}
EOF

echo "Updating Hyprland colors..."
# Update hyprland colors
mkdir -p "$(dirname "$HYPR_COLORS_CONF")"
cat > "$HYPR_COLORS_CONF" <<EOF
# Material You Colors - Generated $(date)
\$primary = rgb(${PRIMARY#"#"})
\$secondary = rgb(${SECONDARY#"#"})
\$tertiary = rgb(${TERTIARY#"#"})
\$surface = rgb(${SURFACE#"#"})
\$on_surface = rgb(${ON_SURFACE#"#"})
\$error = rgb(${ERROR#"#"})

# Apply to Hyprland
general {
    col.active_border = \$primary \$tertiary 45deg
    col.inactive_border = $(hex_to_css_rgba "$SURFACE" "0.5")
}

decoration {
    col.shadow = \$primary
}
EOF

echo "Updating Mako..."
# Update mako notification daemon
mkdir -p "$(dirname "$MAKO_CONFIG")"
cat > "$MAKO_CONFIG" <<EOF
# Material You Theme - Generated $(date)
background-color=$(hex_to_css_rgba "$SURFACE" "0.9")
text-color=$ON_SURFACE
border-color=$PRIMARY
border-size=2
border-radius=10
default-timeout=5000
ignore-timeout=1
font=JetBrainsMono Nerd Font 12

[urgency=high]
background-color=$(hex_to_css_rgba "$ERROR" "0.9")
text-color=$SURFACE
border-color=$ERROR
EOF

#########################
# 7. RELOAD SERVICES    #
#########################

echo "Reloading services..."

# Reload waybar
pkill waybar 2>/dev/null || true
sleep 1
waybar &

# Reload mako
pkill mako 2>/dev/null || true
sleep 1
mako &

# Reload hyprland config (colors only)
hyprctl reload

echo ""
echo "===== MATERIAL YOU + DEPARTURE THEME APPLIED ====="
echo "Wallpaper: $WALLPAPER"
echo "Primary: $PRIMARY"
echo "Secondary: $SECONDARY"
echo "Tertiary: $TERTIARY"
echo "Surface: $SURFACE"
echo "Text: $ON_SURFACE"
echo ""
echo "All applications themed:"
echo "  ✓ Departure (file-based auto-updating)"
echo "  ✓ Waybar"
echo "  ✓ Rofi"
echo "  ✓ Hyprland"
echo "  ✓ Mako"
echo ""
echo "Test with:"
echo "  rofi -show drun"
echo "  departure"
echo "  notify-send 'Test' 'Theme applied!'" 