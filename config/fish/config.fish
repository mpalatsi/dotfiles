source /usr/share/cachyos-fish-config/cachyos-config.fish

# Custom greeting with system info
function fish_greeting
    # Option A: Clean custom message (current)
    # echo "✨ Welcome back! Ready to code?"
    # echo ""
    
    # Option B: Use neofetch instead of fastfetch (uncomment to use)
    # neofetch --ascii_distro arch_small
    
    # Option C: Use fastfetch with custom config (currently active)
    fastfetch --config ~/.config/fastfetch/config.jsonc
    
    # Option D: Simple system info without logo (uncomment to use)
    # echo "🖥️  $(uname -n) | $(date '+%A, %B %d')"
end

# # Pywal color support for fish
# if test -f ~/.cache/wal/sequences
#     cat ~/.cache/wal/sequences
# end

# if test -f ~/.cache/wal/colors.fish
#     source ~/.cache/wal/colors.fish
# end

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
