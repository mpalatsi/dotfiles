#!/bin/bash

# Fastfetch Rice Switcher
# Usage: ./rice-switch.sh [style]

FASTFETCH_DIR="$HOME/.config/fastfetch"

show_help() {
    echo "🎨 Fastfetch Rice Switcher"
    echo "Available styles:"
    echo "  1. original   - Your original table style"
    echo "  2. ultra      - Ultra-riced with emojis"
    echo "  3. minimal    - Minimal elegant style"
    echo "  4. neon       - Neon cyberpunk style"
    echo "  5. gradient   - Gradient color transitions"
    echo ""
    echo "Usage: $0 [style_name]"
    echo "Or run without arguments to see previews"
}

set_config() {
    local style=$1
    case $style in
        "original"|"1")
            cp "$FASTFETCH_DIR/config_arch.jsonc" "$FASTFETCH_DIR/config.jsonc"
            echo "✅ Set to original table style"
            ;;
        "ultra"|"2")
            cp "$FASTFETCH_DIR/config_riced.jsonc" "$FASTFETCH_DIR/config.jsonc"
            echo "✅ Set to ultra-riced style"
            ;;
        "minimal"|"3")
            cp "$FASTFETCH_DIR/config_minimal_rice.jsonc" "$FASTFETCH_DIR/config.jsonc"
            echo "✅ Set to minimal elegant style"
            ;;
        "neon"|"4")
            cp "$FASTFETCH_DIR/config_neon.jsonc" "$FASTFETCH_DIR/config.jsonc"
            echo "✅ Set to neon cyberpunk style"
            ;;
        "gradient"|"5")
            cp "$FASTFETCH_DIR/config_gradient.jsonc" "$FASTFETCH_DIR/config.jsonc"
            echo "✅ Set to gradient style"
            ;;
        *)
            echo "❌ Unknown style: $style"
            show_help
            exit 1
            ;;
    esac
}

preview_all() {
    echo "🎨 Fastfetch Rice Preview:"
    echo ""
    
    configs=("config_arch.jsonc:Original" "config_riced.jsonc:Ultra" "config_minimal_rice.jsonc:Minimal" "config_neon.jsonc:Neon" "config_gradient.jsonc:Gradient")
    
    for config in "${configs[@]}"; do
        IFS=':' read -r file name <<< "$config"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎭 $name Style:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fastfetch --config "$FASTFETCH_DIR/$file" 2>/dev/null | head -20
        echo ""
    done
}

# Main logic
if [ $# -eq 0 ]; then
    echo "Would you like to:"
    echo "1. Preview all styles"
    echo "2. Set a specific style"
    echo ""
    read -p "Choose (1/2): " choice
    
    case $choice in
        1)
            preview_all
            ;;
        2)
            show_help
            echo ""
            read -p "Enter style name or number: " style
            set_config "$style"
            echo ""
            echo "Current style:"
            fastfetch
            ;;
        *)
            show_help
            ;;
    esac
else
    set_config "$1"
    echo ""
    echo "Current style:"
    fastfetch
fi 