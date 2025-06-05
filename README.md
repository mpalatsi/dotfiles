# Material You Dotfiles 🎨

A comprehensive Wayland desktop configuration featuring **Material You** theming with **matugen**, dynamic wallpaper-based color schemes, and modern UI components.

![Desktop Preview](assets/screenshots/desktop.png)

## ✨ Features

### 🎨 **Dynamic Material You Theming**
- **Automatic color extraction** from wallpapers using `matugen`
- **One-click theming** across all applications
- **Material 3 design** principles with modern transparency effects
- **Fallback colors** for reliability

### 🖥️ **Wayland Desktop Environment**
- **Hyprland** - Modern tiling window manager with animations
- **Waybar** - Customizable status bar with Material You styling
- **Rofi** - Beautiful application launcher with sharp modern design
- **Departure** - Modern logout interface with blur effects
- **Mako** - Notification daemon with transparency and Material You colors

### 🎯 **Key Applications Themed**
- Terminal (`alacritty`) with dynamic colors
- GTK applications (3.0/4.0) with consistent theming
- Qt applications via Kvantum
- Fish shell with color integration
- System monitors (`btop`, `cava`)

## 📋 Requirements

### Essential Dependencies
```bash
# Core Wayland components
hyprland waybar rofi mako alacritty

# Theming tools
matugen swww 

# Optional but recommended
departure-git fish btop cava fastfetch
```

### Arch Linux Installation
```bash
# Install from AUR (using paru)
paru -S hyprland waybar rofi mako alacritty matugen swww departure-git

# Or using yay
yay -S hyprland waybar rofi mako alacritty matugen swww departure-git
```

## 🚀 Installation

### Method 1: Automatic Installation (Recommended)
```bash
git clone https://github.com/yourusername/material-you-dotfiles.git
cd material-you-dotfiles
chmod +x install.sh
./install.sh
```

### Method 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/material-you-dotfiles.git
cd material-you-dotfiles

# Backup existing configs
mkdir -p ~/.config/backup
cp -r ~/.config/hypr ~/.config/backup/ 2>/dev/null || true
cp -r ~/.config/waybar ~/.config/backup/ 2>/dev/null || true
# ... backup other configs

# Copy configurations
cp -r config/* ~/.config/

# Make scripts executable
chmod +x ~/.config/hypr/scripts/*.sh
```

## 🎨 Usage

### Applying Themes
The main theming script automatically:
- Sets a random wallpaper from `~/Pictures/Wallpapers/`
- Generates Material You colors using matugen
- Updates all application themes
- Restarts necessary services

```bash
# Apply random wallpaper theme
~/.config/hypr/scripts/pywal-random-theme.sh

# Apply specific wallpaper
~/.config/hypr/scripts/pywal-random-theme.sh /path/to/wallpaper.jpg
```

### Key Bindings
- `Super + D` - Open Rofi application launcher
- `Super + Q` - Open Departure logout menu
- `Super + Enter` - Open terminal
- `Super + Shift + S` - Screenshot with flameshot

## 📁 Directory Structure

```
~/.config/
├── hypr/                     # Hyprland configuration
│   ├── hyprland.conf        # Main config
│   ├── config/              # Modular configurations
│   │   ├── colors.conf      # Dynamic Material You colors
│   │   ├── animations.conf  # Window animations
│   │   └── binds.conf       # Keybindings
│   └── scripts/             # Theming and utility scripts
├── waybar/                   # Status bar
│   ├── config              # Waybar modules
│   ├── style.css           # Dynamic Material You styling
│   └── modules/            # Custom Python modules
├── rofi/                     # Application launcher
│   ├── config.rasi         # Main configuration
│   └── theme.rasi          # Dynamic Material You theme
├── departure/                # Logout interface
│   └── config.json         # Dynamic Material You integration
├── matugen/                  # Material You color generation
│   └── config.toml         # Template configuration
└── mako/                     # Notifications
    └── config              # Dynamic styling with transparency
```

## 🎨 Theming System

### How It Works
1. **Wallpaper Selection**: Random or specified wallpaper
2. **Color Extraction**: Matugen analyzes wallpaper for Material You colors
3. **Template Processing**: Colors applied to configuration templates
4. **Live Updates**: Services restarted to apply new themes
5. **Fallback System**: Reliable fallback colors if extraction fails

### Supported Applications
- ✅ **Hyprland** - Window borders with gradient effects
- ✅ **Waybar** - Status bar with transparent modules
- ✅ **Rofi** - Application launcher with sharp modern design
- ✅ **Departure** - Logout menu with blur and Material You colors
- ✅ **Mako** - Notifications with transparency and app-specific styling
- ✅ **Alacritty** - Terminal with dynamic color schemes
- ✅ **GTK 3/4** - System-wide application theming
- ✅ **Qt/Kvantum** - Qt application theming

### Color Palette
The theming system extracts:
- **Primary** - Main accent color for highlights
- **Tertiary** - Secondary accent for variety
- **Surface** - Background color for dark theme
- **On Surface** - Text color for readability

## 🛠️ Customization

### Adding Wallpapers
```bash
# Add wallpapers to the directory
mkdir -p ~/Pictures/Wallpapers
cp your-wallpapers/* ~/Pictures/Wallpapers/
```

### Modifying Themes
- **Waybar**: Edit `~/.config/waybar/style.css`
- **Rofi**: Modify `~/.config/rofi/theme.rasi`
- **Hyprland**: Update `~/.config/hypr/config/colors.conf`

### Custom Colors
Edit fallback colors in the theming script:
```bash
# Edit ~/.config/hypr/scripts/pywal-random-theme.sh
FALLBACK_BG="#131822"
FALLBACK_FG="#e0e0e0"
FALLBACK_ACCENT="#8f6eff"
```

## 📸 Screenshots

| Component | Preview |
|-----------|---------|
| Desktop Overview | ![Overview](assets/screenshots/overview.png) |
| Rofi Launcher | ![Rofi](assets/screenshots/rofi.png) |
| Waybar Status | ![Waybar](assets/screenshots/waybar.png) |
| Departure Logout | ![Departure](assets/screenshots/departure.png) |
| Notifications | ![Mako](assets/screenshots/notifications.png) |

## 🔧 Troubleshooting

### Matugen Not Working
```bash
# Install matugen
paru -S matugen

# Test color extraction
matugen image --show-colors /path/to/wallpaper.jpg
```

### Services Not Restarting
```bash
# Manually restart services
pkill waybar && waybar &
pkill mako && mako &
```

### Hyprland Colors Not Applying
```bash
# Force reload Hyprland config
hyprctl reload

# Or reload specific config
hyprctl keyword source ~/.config/hypr/config/colors.conf
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Material You** design system by Google
- **Matugen** for color extraction
- **Hyprland** community for the amazing window manager
- All the open source developers who made these tools possible

---

⭐ **Star this repository if you found it helpful!**