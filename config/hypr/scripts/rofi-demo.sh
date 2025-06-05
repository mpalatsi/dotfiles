#!/bin/bash
# Rofi Demo Script - Shows different modes with the new dark theme

echo "🎨 Rofi Dark Theme Demo"
echo "======================="
echo ""
echo "Available demo modes:"
echo "1. Applications (drun)"
echo "2. Run commands (run)"
echo "3. Windows (window)"
echo "4. File browser (filebrowser)"
echo ""

read -p "Choose a mode (1-4) or press Enter for applications: " choice

case $choice in
    1|"")
        echo "🚀 Launching Applications mode..."
        rofi -show drun
        ;;
    2)
        echo "⚡ Launching Run mode..."
        rofi -show run
        ;;
    3)
        echo "🪟 Launching Windows mode..."
        rofi -show window
        ;;
    4)
        echo "📁 Launching File browser mode..."
        rofi -show filebrowser
        ;;
    *)
        echo "❌ Invalid choice. Launching default Applications mode..."
        rofi -show drun
        ;;
esac

echo "✅ Rofi demo completed!" 