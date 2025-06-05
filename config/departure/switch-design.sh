#!/bin/bash

# Departure Design Switcher
# Usage: ./switch-design.sh [design-name]

DESIGNS_DIR="$HOME/.config/departure/designs"
CONFIG_FILE="$HOME/.config/departure/config.json"

# Available designs
designs=(
    "elegant-grid:🎨 Elegant Grid Layout with Custom Icons"
    "minimal-horizontal:✨ Minimal Horizontal Strip"
    "material-you:🌈 Material You Dynamic Colors"
    "compact-vertical:📱 Compact Vertical Sidebar"
)

show_menu() {
    echo "🚪 Departure Design Switcher"
    echo "=============================="
    echo
    
    for i in "${!designs[@]}"; do
        design_name=$(echo "${designs[$i]}" | cut -d':' -f1)
        design_desc=$(echo "${designs[$i]}" | cut -d':' -f2)
        echo "$((i+1)). $design_desc"
    done
    
    echo
    echo "0. Exit"
    echo
}

switch_design() {
    local design_file="$DESIGNS_DIR/$1.json"
    
    if [[ -f "$design_file" ]]; then
        cp "$design_file" "$CONFIG_FILE"
        echo "✅ Successfully switched to '$1' design!"
        echo "🔄 Changes will take effect on next departure launch."
        
        # Optional: Auto-restart waybar to reflect changes
        if command -v waybar >/dev/null 2>&1; then
            echo "🔄 Restarting waybar..."
            killall waybar 2>/dev/null
            nohup waybar >/dev/null 2>&1 &
        fi
    else
        echo "❌ Design '$1' not found!"
        exit 1
    fi
}

preview_design() {
    local design_name="$1"
    local design_file="$DESIGNS_DIR/$design_name.json"
    
    if [[ -f "$design_file" ]]; then
        echo "🎨 Preview of '$design_name' design:"
        echo "======================================"
        
        # Extract key properties for preview
        layout_type=$(jq -r '.layout.layout_type' "$design_file")
        button_size=$(jq -r '.layout.button_size' "$design_file")
        button_spacing=$(jq -r '.layout.button_spacing' "$design_file")
        theme_source=$(jq -r '.theme.source' "$design_file")
        
        echo "Layout: $layout_type"
        echo "Button Size: ${button_size}px"
        echo "Spacing: ${button_spacing}px"
        echo "Theme Source: $theme_source"
        
        if [[ "$theme_source" == "manual" ]]; then
            primary_color=$(jq -r '.theme.manual_colors.primary' "$design_file")
            echo "Primary Color: $primary_color"
        fi
        
        echo
    fi
}

# Main script logic
if [[ $# -eq 1 ]]; then
    # Direct design name provided
    switch_design "$1"
    exit 0
fi

# Interactive menu
while true; do
    show_menu
    read -p "Select a design (0-${#designs[@]}): " choice
    
    case $choice in
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        [1-9]*)
            if [[ $choice -le ${#designs[@]} ]]; then
                design_name=$(echo "${designs[$((choice-1))]}" | cut -d':' -f1)
                preview_design "$design_name"
                
                read -p "Switch to this design? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    switch_design "$design_name"
                    break
                fi
            else
                echo "❌ Invalid selection!"
            fi
            ;;
        *)
            echo "❌ Invalid selection!"
            ;;
    esac
    
    echo
done 