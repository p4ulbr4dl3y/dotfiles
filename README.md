# Dotfiles

My Arch Linux + Hyprland dotfiles managed with GNU Stow.

## Structure

| Package | Description |
|---------|-------------|
| `hyprland` | Hyprland WM & hyprpaper configs |
| `waybar` | Waybar status bar |
| `rofi` | Rofi app launcher |
| `foot` | Foot terminal |
| `kitty` | Kitty terminal |
| `shell` | Zsh, Bash, Fish configs |
| `mako` | Mako notification daemon |
| `btop` | Btop system monitor |
| `micro` | Micro editor |
| `mpv` | MPV media player |
| `gtk` | GTK theme settings |
| `pcmanfm` | PCManFM file manager |
| `xsettingsd` | X settings daemon |
| `git` | Git configuration |

## Installation

### Prerequisites

```bash
# Arch Linux
sudo pacman -S stow
```

### Deploy configs

```bash
cd ~/dotfiles

# Install all configs
stow .

# Or install specific packages
stow hyprland
stow waybar
stow shell
```

### Undeploy configs

```bash
stow -D package_name
```

## Quick Setup (New Installation)

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
stow .
```

## Notes

- Some configs may need adjustment for your specific hardware/setup
- Create `*-local` override files for machine-specific settings
- Check individual package READMEs for package-specific notes

## License

Feel free to use and modify for your own setup.
